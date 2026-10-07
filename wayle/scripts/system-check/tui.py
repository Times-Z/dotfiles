"""The Textual dashboard that needs rich textual and a terminal"""

import sys
from datetime import datetime

from rich.text import Text
from textual.app import App, Binding, ComposeResult
from textual.containers import Container, Horizontal
from textual.events import Resize
from textual.geometry import Size
from textual.screen import ModalScreen
from textual.widgets import DataTable, Footer, Input, Log, Static

from checks import SECTIONS, collect_logs
from const import (
    Record,
    STATUS_OK,
    STATUS_WARN,
    Status,
    TUI_REFRESH_SECONDS,
    UPDATE_SOURCES,
    UPDATES_CACHE_SECONDS,
)
from panels import (
    DRACULA,
    FLAT_PANELS,
    STATUS_GLYPHS,
    TABLE_SPECS,
    TUI_SECTIONS,
    UPDATES_WIDTHS,
    drill_items,
    table_caption,
)
from updates import (
    collect_updates,
    load_updates_cache,
    run_updates,
    save_updates_cache,
)
from util import hostname_facts, worst_of


class PagedTable(DataTable):
    """DataTable where home and end move the cursor itself so enter opens what you see"""

    BINDINGS = [Binding("home", "first_row", "top"), Binding("end", "last_row", "bottom")]

    def action_first_row(self) -> None:
        if self.row_count:
            self.move_cursor(row=0)

    def action_last_row(self) -> None:
        if self.row_count:
            self.move_cursor(row=self.row_count - 1)


class LogsScreen(ModalScreen[None]):
    """One unit journal floating above the dashboard"""

    CSS = f"""
    LogsScreen {{ align: center middle; }}
    #logbox {{ width: 94%; height: 86%; border: round {DRACULA["comment"]}; border-title-align: left; }}
    #logbox Log {{ width: 100%; height: 1fr; }}
    """
    BINDINGS = [Binding("enter", "dismiss", "back"), Binding("escape", "dismiss", "back"),
                Binding("h", "dismiss", "back"), Binding("r", "fetch", "reload"),
                # modals swallow app plain keys on purpose so u deserves the exception
                Binding("u", "app.reload_updates", show=False)]

    def __init__(self, unit: str, user: bool) -> None:
        super().__init__()
        self.unit, self.user = unit, user

    def compose(self) -> ComposeResult:
        with Container(id="logbox"):
            yield Log(id="log")

    def on_mount(self) -> None:
        self.query_one("#logbox").border_title = f"logs · {self.unit}"
        self.query_one(Log).focus()
        self.action_fetch()

    def action_fetch(self) -> None:
        log = self.query_one(Log)
        log.clear()
        log.write_lines(collect_logs(self.unit, self.user))


class CheckApp(App[None]):
    """The dashboard app with sections on the left and the live detail on the right"""

    ENABLE_COMMAND_PALETTE = False
    CSS = f"""
    Screen {{ background: {DRACULA["bg"]}; }}
    #badge {{ height: 1; padding: 0 1; background: {DRACULA["current"]}; }}
    Footer {{ background: {DRACULA["current"]}; }}
    #nav {{ width: 24; border: round {DRACULA["comment"]}; }}
    #detail {{ width: 1fr; }}
    #detail Static {{ width: 100%; height: 100%; }}
    DataTable {{ width: 100%; height: 100%; }}
    #detail DataTable {{ border: round {DRACULA["comment"]}; border-title-align: left; }}
    DataTable > .datatable--cursor {{ background: {DRACULA["comment"]}; color: {DRACULA["bg"]}; }}
    #search {{ display: none; width: 100%; height: 1; border: none;
               padding: 0 1; background: {DRACULA["current"]}; color: {DRACULA["fg"]}; }}
    """
    BINDINGS = [
        Binding("q", "quit", "quit", priority=True),
        Binding("r", "reload", "refresh"),
        Binding("slash", "search", "search"),
        Binding("j", "cursor(1)", show=False), Binding("k", "cursor(-1)", show=False),
        Binding("escape", "back", "back"), Binding("h", "back", show=False),
        *[Binding(str(number), f"jump({number - 1})", show=False) for number in range(1, 10)],
        Binding("0", f"jump({len(SECTIONS)})", show=False),
        Binding("u", "reload_updates", "updates"),
        Binding("U", "apply_updates", "update"),
    ]

    def __init__(self) -> None:
        super().__init__()
        self.host = hostname_facts().get("Static hostname", "")
        self.data: list[Record] = [None] * len(TUI_SECTIONS)
        self.statuses: list[Status] = [STATUS_OK] * len(TUI_SECTIONS)
        self.filter = ""
        self.shown = 0
        self.updates_loading = False
        self._updates_toast = False

    def compose(self) -> ComposeResult:
        yield Static("", id="badge")
        with Horizontal():
            yield DataTable(id="nav", cursor_type="row", cursor_background_priority="css")
            yield Container(id="detail")
        yield Input(placeholder="/ text to find · enter rows · esc cancels", id="search")
        yield Footer()

    def on_mount(self) -> None:
        nav = self.query_one("#nav", DataTable)
        nav.add_columns(("", "glyph"), ("SECTION", "section"))
        for section in TUI_SECTIONS:
            glyph, color = STATUS_GLYPHS[STATUS_OK]
            nav.add_row(Text(glyph, style=color), section.name, key=section.name)
        self.refresh_data()
        nav.focus()
        self.set_interval(TUI_REFRESH_SECONDS, self.refresh_data)

    def show_section(self, row: int) -> None:
        self.shown = row
        name = TUI_SECTIONS[row].name
        detail = self.query_one("#detail", Container)
        detail.remove_children()
        if name in TABLE_SPECS:
            headers, build = TABLE_SPECS[name]
            table = PagedTable(cursor_type="row", cursor_background_priority="css")
            detail.mount(table)
            if name == "UPDATES":
                for header, width in zip(headers, UPDATES_WIDTHS):
                    table.add_column(header, width=width)
                table.add_column(headers[-1])
            else:
                table.add_columns(*headers)
            for cells in build(self.data[row], self.filter):
                table.add_row(*cells)
            table.border_title = self.detail_title(name, self.data[row], table, 0)
            if name == "UPDATES":
                table.call_after_refresh(lambda: self.fit_updates_columns(table))
        else:
            if self.filter:  # flat panels have nothing to filter
                self.filter = ""
                search = self.query_one(Input)
                search.display = False
                search.value = ""
            try:
                panel = FLAT_PANELS[name](self.data[row])
            except Exception as exc:  # a broken panel must not kill the app
                panel = Text(f"panel failed: {exc}", style=DRACULA["red"])
            detail.mount(Static(panel))

    def fit_updates_columns(self, table: DataTable) -> None:
        """Pin the description column to the leftover space so updates fills the pane"""
        columns = list(table.columns.values())
        gutter = 2 * table.cell_padding
        others = sum(column.width + gutter for column in columns[:-1])
        column = columns[-1]
        column.auto_width = False
        column.width = max(8, table.size.width - others - gutter)
        column.content_width = column.width
        table.virtual_size = Size(
            others + column.width + gutter, table.virtual_size.height
        )
        table.refresh()

    def on_resize(self, event: Resize) -> None:
        """Repin the updates description column once the window settles at its new width"""
        if TUI_SECTIONS[self.shown].name != "UPDATES":
            return
        tables = self.query("#detail DataTable")
        if len(tables):
            table = tables[0]
            table.call_after_refresh(lambda: self.fit_updates_columns(table))

    def refresh_detail(self) -> None:
        """Tables redraw in place keeping focus and cursor and only remount when the kind changed"""
        name = TUI_SECTIONS[self.shown].name
        tables = self.query("#detail DataTable")
        if name in TABLE_SPECS and tables:
            table = tables[0]
            coord = table.cursor_coordinate
            keep = coord.row if coord else 0
            table.clear()
            for cells in TABLE_SPECS[name][1](self.data[self.shown], self.filter):
                table.add_row(*cells)
            if name == "UPDATES":
                self.fit_updates_columns(table)
            if table.row_count:
                keep = min(keep, table.row_count - 1)
                table.move_cursor(row=keep)
            table.border_title = self.detail_title(name, self.data[self.shown], table, keep)
            return
        self.show_section(self.shown)

    def refresh_data(self) -> None:
        data: list[Record] = []
        statuses: list[Status] = []
        for index, section in enumerate(TUI_SECTIONS):
            if section.name == "UPDATES":
                # owned by the disk cache and the background worker with the dim
                # dot standing while neither has anything to show yet
                cached = self.data[index] or load_updates_cache()
                data.append(cached)
                statuses.append(
                    "" if cached is None else (STATUS_WARN if cached["records"] else STATUS_OK)
                )
                continue
            try:
                collected = section.collect()
                statuses.append(worst_of(section.rows(collected)))
            except Exception:  # a broken section just goes warn
                collected = None
                statuses.append(STATUS_WARN)
            data.append(collected)
        self.data, self.statuses = data, statuses
        self.update_badge()
        nav = self.query_one("#nav", DataTable)
        for section, status in zip(TUI_SECTIONS, statuses):
            glyph, color = STATUS_GLYPHS[status]
            nav.update_cell(section.name, "glyph", Text(glyph, style=color))
        self.ensure_updates()
        self.refresh_detail()

    def update_badge(self) -> None:
        all_ok = all(status == STATUS_OK for status in self.statuses[: len(SECTIONS)])
        badge = Text.assemble(
            ("system-check ", f"bold {DRACULA['pink']}"),
            (f"· {self.host} · {datetime.now():%H:%M:%S}  ", DRACULA["comment"]),
            (" ALL OK ", f"bold {DRACULA['bg']} on {DRACULA['green']}")
            if all_ok
            else (" ALERT ", f"bold {DRACULA['bg']} on {DRACULA['red']}"),
            ("   arrows/PgDn walk · / search · enter logs · esc back · r refresh · q quit", DRACULA["comment"]),
        )
        self.query_one("#badge", Static).update(badge)

    def on_data_table_row_highlighted(self, message: DataTable.RowHighlighted) -> None:
        if message.data_table.id == "nav":
            if message.cursor_row != self.shown:
                self.show_section(message.cursor_row)
            return
        name = TUI_SECTIONS[self.shown].name
        if name in TABLE_SPECS and message.cursor_row is not None:
            message.data_table.border_title = self.detail_title(
                name, self.data[self.shown], message.data_table, message.cursor_row
            )

    def detail_title(self, name: str, data: Record, table: DataTable, cursor_row: int) -> str:
        """Table title enriched with filter count and cursor position"""
        title = table_caption(name, data)
        if self.filter:
            title += f' · "{self.filter}" {table.row_count} found'
        if table.row_count:
            title += f" · line {cursor_row + 1}/{table.row_count}"
        return title

    def on_data_table_row_selected(self, message: DataTable.RowSelected) -> None:
        if message.data_table.id == "nav":
            tables = self.query("#detail DataTable")
            if tables:
                # a tick later or the nav enter handling undoes it itself
                table = tables[0]
                self.set_timer(0.01, lambda: self.set_focus(table))
                message.stop()
            return
        name = TUI_SECTIONS[self.shown].name
        items = drill_items(name, self.data[self.shown], self.filter)
        if message.cursor_row is not None and 0 <= message.cursor_row < len(items):
            self.push_screen(LogsScreen(items[message.cursor_row], name == "USER UNITS"))

    def action_search(self) -> None:
        """Open the live filter box like the pager slash key"""
        if len(self.screen_stack) > 1 or TUI_SECTIONS[self.shown].name not in TABLE_SPECS:
            return
        search = self.query_one(Input)
        search.display = True
        search.focus()

    def on_input_changed(self, message: Input.Changed) -> None:
        self.filter = message.value.lower()
        self.refresh_detail()

    def on_input_submitted(self, message: Input.Submitted) -> None:
        tables = self.query("#detail DataTable")
        if tables:
            tables[0].focus()

    def action_jump(self, index: int) -> None:
        nav = self.query_one("#nav", DataTable)
        if index < nav.row_count:
            nav.focus()
            nav.move_cursor(row=index, animate=False)

    def action_back(self) -> None:
        """Up one level closing the search box first and handing arrows back to the nav"""
        search = self.query_one(Input)
        if search.display:
            search.display = False
            self.filter = ""
            search.value = ""
            self.refresh_detail()
            tables = self.query("#detail DataTable")
            if tables:
                tables[0].focus()
            return
        if len(self.screen_stack) > 1:
            return  # a modal is open and its own keys handle it
        self.query_one("#nav", DataTable).focus()

    def action_cursor(self, direction: int) -> None:
        """Move the cursor for fingers that stay on the home row"""
        widget = self.focused
        if isinstance(widget, DataTable):
            widget.action_cursor_down() if direction > 0 else widget.action_cursor_up()

    def action_reload(self) -> None:
        self.refresh_data()

    def ensure_updates(self, force: bool = False) -> None:
        """Background refetch when the cache ages without ever blocking the UI"""
        if self.updates_loading:
            return
        cached = self.data[len(SECTIONS)]
        if not force and cached is not None:
            if (datetime.now() - cached["checked"]).total_seconds() < UPDATES_CACHE_SECONDS:
                return
        self.updates_loading = True
        self.run_worker(self._updates_worker, thread=True, exclusive=True)

    def _updates_worker(self) -> None:
        updates = collect_updates()
        if len(updates["missing"]) < len(UPDATE_SOURCES):
            save_updates_cache(updates)  # so the bar polls benefit too
        try:
            self.call_from_thread(self._apply_updates, updates)
        except Exception:  # the app may be gone when a slow fetch returns
            pass

    def _apply_updates(self, updates: Record) -> None:
        self.updates_loading = False
        self.data[len(SECTIONS)] = updates
        if self._updates_toast:  # only answer back when u asked for it
            self._updates_toast = False
            count = len(updates["records"])
            if updates["missing"]:
                self.notify("sources down: " + " + ".join(updates["missing"]), title="updates",
                            severity="warning", timeout=3.0)
            elif count:
                self.notify(f"{count} package updates pending", title="updates", timeout=3.0)
            else:
                self.notify("up to date", title="updates", timeout=3.0)
        self.refresh_data()

    def action_reload_updates(self) -> None:
        """Force an update recheck with a dim dot and toasts as feedback"""
        self.statuses[len(SECTIONS)] = ""
        glyph, color = STATUS_GLYPHS[""]
        self.query_one("#nav", DataTable).update_cell("UPDATES", "glyph", Text(glyph, style=color))
        self._updates_toast = True
        self.notify("checking for updates...", title="updates", timeout=2.0)
        self.ensure_updates(force=True)

    def action_apply_updates(self) -> None:
        """Hand the terminal to the updater then repaint and recheck"""
        with self.suspend():
            run_updates()
        self.refresh_data()
        self.ensure_updates(force=True)


def run_tui() -> int:
    """Run the dashboard until quit and say so politely without a terminal"""
    if not (sys.stdin.isatty() and sys.stdout.isatty()):
        print("the dashboard needs a terminal (try it from kitty)", file=sys.stderr)
        return 1
    CheckApp().run()
    return 0
