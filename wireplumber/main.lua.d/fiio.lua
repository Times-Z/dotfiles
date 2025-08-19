rule = {
  matches = {
    {
      { "node.name", "equals", "alsa_output.usb-FIIO_FiiO_K11-01.pro-output-0" },
    },
  },
  apply_properties = {
    ["audio.format"] = "S32LE",   -- 32-bit PCM
    ["audio.rate"]   = 384000,    -- lock 384 kHz
  },
}

table.insert(alsa_monitor.rules, rule)
