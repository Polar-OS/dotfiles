# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc

# Disable systemd OSC context tracking (conflicts with Atuin)
# This removes the systemd command tracking that uses OSC 3008 sequences
unset -f __systemd_osc_context_precmdline __systemd_osc_context_ps0 2>/dev/null
PROMPT_COMMAND=()  # Clear PROMPT_COMMAND array
PS0=''  # Clear PS0

# Debug logging for Atuin (remove after testing)
export ATUIN_LOG=debug

# Force bash to be more interactive-like even when not a login shell
# This helps bash-preexec work correctly
shopt -s histappend

[[ -f ~/.bash-preexec.sh ]] && source ~/.bash-preexec.sh
eval "$(atuin init bash --disable-up-arrow)"
export OPENCODE_EXPERIMENTAL_FILEWATCHER=true
