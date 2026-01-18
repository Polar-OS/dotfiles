# PATH #########################################################################
use std "path add"

path add  "~/.local/bin"
path add  "~/.cargo/bin"
path add  "~/go/bin"
path add  "~/.npm-packages/bin"
path add  "~/.local/share/soar/bin"

# ENV #########################################################################
$env.EDITOR = "nvim"
$env.SHELL = "/usr/bin/nu"
$env.TERM = "xterm-256color"

$env.TMUX_PLUGIN_MANAGER_PATH = "~/.config/tmux/plugins"

# Generate code for utilities
# zoxide
zoxide init nushell | save -f ~/.zoxide.nu

# atuin
atuin init nu --disable-up-arrow | save -f ~/.local/share/atuin/init.nu

# starship
mkdir ($nu.data-dir | path join "vendor/autoload")
starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")

# carapace
$env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense'
mkdir ~/.cache/carapace
carapace _carapace nushell | save --force ~/.cache/carapace/init.nu
