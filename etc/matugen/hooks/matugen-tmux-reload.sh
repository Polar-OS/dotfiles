#!/usr/bin/env bash
tmux source-file ~/.config/tmux/colors.conf
tmux source-file ~/.config/tmux/conf/theme.conf
tmux run-shell ~/.config/tmux/plugins/tmux-cpu/cpu.tmux
tmux run-shell ~/.config/tmux/plugins/tmux-battery/battery.tmux
~/.config/tmux/scripts/sync_gtk_theme.sh
