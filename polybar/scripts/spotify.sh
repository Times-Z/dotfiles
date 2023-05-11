#!/bin/bash

# Author : https://github.com/Crash-Zeus

readonly command=$1

# Set the source audio player here.
# Examples: spotify, vlc, chrome, mpv and others.
# See more here: https://github.com/altdesktop/playerctl/#selecting-players-to-control
readonly PLAYER="spotifyd"

# Delay (in seconds) for scrolling update; lower this for faster scrolling
readonly ZSCROLL_DELAY="0.1"

# Time in seconds to wait in between running update checking commands
readonly ZSCROLL_UPDATE_DELAY="2"

# if display text > length the text is going to scroll
readonly ZSCROLL_LENGTH="20"

function get_status {
    PLAYERCTL_STATUS=$(playerctl --player=$PLAYER status)
    EXIT_CODE=$?
    
    if [ $EXIT_CODE -eq 0 ]; then
        STATUS=$PLAYERCTL_STATUS
    else
        STATUS="No player is running"
    fi
}

function get_metadata {
    DATA=$(playerctl --player=$PLAYER metadata --format "$1")
    echo $DATA
}

function display_data {
    if [ "$STATUS" = "Stopped" ]; then
        echo " "
    elif [ "$STATUS" = "Paused"  ]; then
        get_metadata "Paused"
    elif [ "$STATUS" = "No player is running"  ]; then
        echo "$STATUS"
    else
        get_metadata "{{ title }} by {{ artist }}"
    fi
}

function display_status {
    if [ "$STATUS" = "Stopped" ]; then
        echo ""
    elif [ "$STATUS" = "Paused"  ]; then
        echo ""
    elif [ "$STATUS" = "No player is running"  ]; then
        echo ""
    else
        echo ""
    fi
}

function exec_player_command {
    readonly CMD=$1
    playerctl --player=$PLAYER $CMD
}

case $command in

    "--get-infos")
        get_status
        display_data
    ;;
 
    "--get-status")
        get_status
        display_status
    ;;

  "--get-status-exit-code")
      get_status
      if [ "$STATUS" == "Stopped" ] || [ "$STATUS" == "No player is running"] ;
      then
        exit 1
      fi
    ;;
    
    "--scroll")
        $0 --get-infos | zscroll -d $ZSCROLL_DELAY -U $ZSCROLL_UPDATE_DELAY -l $ZSCROLL_LENGTH -u true "`dirname $0`/spotify.sh --get-infos"
        # -d update scroll delay
        # -U launch update command delay
        # -l length of scrolling text
        # -u Update command
    ;;
    
    "--play-pause")
        get_status
        if [ "$STATUS" = "Playing" ] ; then
            exec_player_command pause
        elif [ "$STATUS" = "Paused" ] ; then
            exec_player_command play
        elif [ "$STATUS" = "Stopped" ] ; then
            exec_player_command play
        fi
    ;;

    "--next")
        exec_player_command next
    ;;

    "--previous")
        exec_player_command previous
    ;;

    *)
        echo "No command specified."
        echo ""
        echo "Available commands :"
        echo "--get-infos                   Get the song name if playing or return No playing song / Paused"
        echo "--get-status                  Get the current status of player (Playing|Stopped|Paused)"
        echo "--scroll                      Display the song metadata with zscroll to scroll text"
        echo "--play-pause                  Execute play or pause command (depend on playerctl status)"
        echo "--next                        Execute next command"
        echo "--previous                    Execute previous command"
        exit 0
    ;;
esac
