
# Install tpm if not installed

def install_plugins [] {
    if not ($nu.home-path | path join ".config/tmux/plugins/tpm" | path exists) {
        ^git clone https://github.com/tmux-plugins/tpm ($nu.home-path | path join ".config/tmux/plugins/tpm")
        # si quisieras ejecutar el install_plugins también:
        # ^TMUX_PLUGIN_MANAGER_PATH=($nu.home-path | path join ".config/tmux/plugins") \
          ^($nu.home-path | path join ".config/tmux/plugins/tpm/bin/install_plugins")
        tmux source-file ~/.config/tmux/tmux.conf
    }
}

install_plugins
