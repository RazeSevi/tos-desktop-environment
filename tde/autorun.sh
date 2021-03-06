#!/usr/bin/env bash

# MIT License
# 
# Copyright (c) 2019 manilarome
# Copyright (c) 2020 Tom Meyers
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

userlocation="$HOME/.config/tos/autostart"

if [[ -f "$HOME/.config/tos/autostart/config" ]]; then
        userlocation=$(grep -E "location" "$HOME"/.config/tos/autostart/config | cut -d= -f2)
fi


function run() {
  if ! pgrep -f "$1"; then
    "$@" &
  fi
}

setxkbmap "$(cut -d= -f2 /etc/vconsole.conf | cut -d- -f1)"

if [[ "$(command -v light-locker)" ]]; then
    light-locker --no-lock-on-suspend &>/dev/null &
fi

if [[ "$(command -v udiskie)" ]]; then
    pgrep udiskie &>/dev/null || udiskie &>/dev/null &
fi

if [[ "$(command -v psi-notify)" ]]; then
    pgrep psi-notify &>/dev/null || psi-notify &>/dev/null &
fi

if grep -q "bluetooth=false" ~/.config/tos/theme; then
        pgrep bluetoothctl &>/dev/null || bluetoothctl power off
fi

# launch a polkit authentication manager
if [[ "$(command -v lxsession)" ]]; then
    pgrep lxsession || lxsession -s TOS -e TDE &
fi

# autolock the system
if [[ "$(command -v xidlehook)" != "" && "$1" -gt "5" ]]; then
    echo "Lock screen time set to: $1 seconds"
    sh /etc/xdg/tde/autolock.sh "$1" &>/dev/null &
fi

# run clipboard manager
if [[ "$(command -v greenclip)" ]]; then
    pgrep greenclip || greenclip daemon
fi

# run kde connect
if [[ -f "/usr/lib/kdeconnectd" ]]; then
    pgrep kdeconnectd || /usr/lib/kdeconnectd &
fi

if [[ "$(command -v touchegg)" ]]; then
    [[ "$(pgrep touchegg | wc -l)" -lt 2 ]] && touchegg &
fi

# autostart user scripts if that directory exists
if [[ -d "$userlocation" ]]; then
        for script in "$userlocation"/*.sh; do
            "$script" & # launch all user scripts in the background
        done
fi

