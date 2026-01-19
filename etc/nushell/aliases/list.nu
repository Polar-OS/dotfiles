#  Listing aliases
# alias ls = eza -l -G --icons --no-permissions --no-user --no-time --no-filesize" alias tree="eza -l -G --icons --no-permissions --no-user --no-time --no-filesize -T
# alias l = eza -lbF --git 
# alias ll = eza -lbGF --git
alias ll = ls -l
alias la = ls -la

# eza specialty views
alias lx = eza -lbhHigUmuSa@ --time-style=long-iso --git --color-scale
alias llm = eza -lbGd --git --sort=modified
alias lS = eza -1
alias lt = eza --tree --level=2
