# source atuin generated code with
# atuin init nu | save ~/.local/share/atuin/init.nu
# IMPORTANT: Load Atuin BEFORE configuring $env.config
source ~/.local/share/atuin/init.nu

# CONFIG #####################################################################
$env.config.buffer_editor = "nvim"
$env.config.edit_mode = 'vi'

$env.config.show_banner = false

# Configure history to not interfere with Atuin
$env.config.history = {
    file_format: "plaintext"
    sync_on_enter: true
    max_size: 100000
}

# ALIASES #####################################################################

# source list aliases
source ~/.config/nushell/aliases/list.nu

# source git aliases
source ~/.config/nushell/aliases/git.nu

# source atuin aliases
source ~/.config/nushell/aliases/atuin.nu

# source short aliases
source ~/.config/nushell/aliases/short.nu

# source distrobox aliases
source ~/.config/nushell/aliases/distrobox.nu

# source jj aliases
source ~/.config/nushell/aliases/jj.nu

# source workmux aliases
source ~/.config/nushell/aliases/workmux.nu

# source opencode aliases
source ~/.config/nushell/aliases/opencode.nu


# source functions
source ~/.config/nushell/aliases/functions.nu

# UTILS #######################################################################

# source zoxide generated code with
# zoxide init nushell | save -f ~/.zoxide.nu
source ~/.zoxide.nu

# source the startup file
source ~/.config/nushell/scripts/startup.nu


# source you-should-use plugin
source ~/.config/nushell/scripts/you-should-use.nu

# source carapace completions
source ~/.cache/carapace/init.nu
