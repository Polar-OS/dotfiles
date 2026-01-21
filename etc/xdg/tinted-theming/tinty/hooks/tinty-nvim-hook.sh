#!/bin/bash

# Tinty pasa la ruta del archivo de tema generado en la variable de entorno
THEME_FILE="$TINTY_THEME_FILE_PATH"

if [ -z "$THEME_FILE" ]; then
  echo "Error: TINTY_THEME_FILE_PATH is not set"
  exit 1
fi

# Copiar el contenido al archivo de configuración estándar de tinted-vim
# Esto es lo que el plugin base16-vim espera leer
mkdir -p "$HOME/.config/nvim"
cat "$THEME_FILE" > "$HOME/.vimrc_background"

# Guardar estado para que nvim sepa qué cargar al reinicio
echo 'return { type = "tinty" }' > "$HOME/.config/nvim/lua/custom/theme_state.lua"

# Notificar a todas las instancias de Neovim
# Buscamos sockets en /run/user/$UID/nvim.*
for socket in /run/user/$(id -u)/nvim.*; do
  if [ -S "$socket" ]; then
    # Enviamos el comando para recargar la configuración
    # Usamos --headless para evitar abrir una UI, y --remote-send para enviar teclas/comandos
    # <C-\><C-N> asegura salir del modo inserción/terminal antes de ejecutar el comando
    nvim --server "$socket" --remote-send "<C-\><C-N>:source ~/.vimrc_background<CR>" >/dev/null 2>&1 &
  fi
done

echo "Applied theme to Neovim"
