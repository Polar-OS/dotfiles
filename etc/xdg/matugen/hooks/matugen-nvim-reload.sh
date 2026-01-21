#!/bin/bash

# Guardar estado para que nvim sepa qué cargar al reinicio
echo 'return { type = "matugen" }' > "$HOME/.config/nvim/lua/custom/theme_state.lua"

# Notificar a instancias activas
for socket in /run/user/$(id -u)/nvim.*; do
  if [ -S "$socket" ]; then
    # Recargar el modulo lua y ejecutar setup
    nvim --server "$socket" --remote-send "<C-\><C-N>:lua package.loaded['custom.matugen_theme'] = nil; require('custom.matugen_theme').setup()<CR>" >/dev/null 2>&1 &
  fi
done
