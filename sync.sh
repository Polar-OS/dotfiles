#!/bin/bash

REPO_DIR="/tmp/dotfiles-repo"
XDG_DEST_DIR="./etc/xdg"
SKEL_DEST_DIR="./etc/skel"
PROFILE_D_DIR="./etc/profile.d"
SSH_DEST_DIR="./etc/ssh"

mkdir -p "$XDG_DEST_DIR"
mkdir -p "$SKEL_DEST_DIR"
mkdir -p "$PROFILE_D_DIR"
mkdir -p "$SSH_DEST_DIR"

transform_name() {
    local name="$1"
    local result="${name}"
    result="${result//dot_/.}"
    result="${result//private_/}"
    result="${result//executable_/}"
    result="${result//readonly_/}"
    result="${result//.tmpl/}"
    echo "$result"
}

process_item() {
    local item="$1"
    local relative_path="$2"

    local base=$(basename "$item")
    
    if [[ "$base" == ".git" || "$base" == ".chezmoiroot" || "$base" == ".chezmoidata" ]]; then
        return
    fi

    local new_base=$(transform_name "$base")

    if [[ "$new_base" == ".config" && -z "$relative_path" ]]; then
        for subitem in "$item"/*; do
            [ -e "$subitem" ] || continue
            process_item "$subitem" ""
        done
        return
    elif [[ "$new_base" == ".local" && -z "$relative_path" ]]; then
        for subitem in "$item"/*; do
            [ -e "$subitem" ] || continue
            process_item "$subitem" ""
        done
        return
    fi

    local target_root="$XDG_DEST_DIR"
    local final_name="$new_base"
    
    if [ -z "$relative_path" ]; then
        if [[ "$new_base" == ".bashrc" ]]; then
            target_root="$PROFILE_D_DIR"
            final_name="99-global-bashrc.sh"
        elif [[ "$new_base" == ".zshrc" ]]; then
            target_root="./etc"
            final_name="zshrc"
        elif [[ "$new_base" == ".ssh" ]]; then
            target_root="$SSH_DEST_DIR"
            final_name="ssh_config.d"
        elif [[ "$new_base" == .* ]]; then
            target_root="$XDG_DEST_DIR"
            final_name="${new_base#.}"
        fi
    fi

    local new_path
    if [ -z "$relative_path" ]; then
        new_path="$target_root/$final_name"
    else
        new_path="$target_root/$relative_path/$new_base"
    fi

    if [ -d "$item" ]; then
        mkdir -p "$new_path"
        for subitem in "$item"/*; do
            [ -e "$subitem" ] || continue
            local sub_relative
            if [ -z "$relative_path" ]; then
                sub_relative="$final_name"
            else
                sub_relative="$relative_path/$new_base"
            fi
            process_item_recursive "$subitem" "$sub_relative" "$target_root"
        done
        find "$new_path" -name ".git" -exec rm -rf {} +
        find "$new_path" -name ".gitmodules" -exec rm -f {} +
    else
        cp "$item" "$new_path"
        if [[ "$base" == executable_* ]]; then
            chmod +x "$new_path"
        fi
    fi
}

process_item_recursive() {
    local item="$1"
    local relative_parent="$2"
    local target_root="$3"

    local base=$(basename "$item")
    
    if [[ "$base" == ".git" || "$base" == ".gitmodules" ]]; then
        return
    fi

    local new_base=$(transform_name "$base")
    local new_path="$target_root/$relative_parent/$new_base"

    if [ -d "$item" ]; then
        mkdir -p "$new_path"
        for subitem in "$item"/*; do
            [ -e "$subitem" ] || continue
            process_item_recursive "$subitem" "$relative_parent/$new_base" "$target_root"
        done
    else
        cp "$item" "$new_path"
        if [[ "$base" == executable_* ]]; then
            chmod +x "$new_path"
        fi
    fi
}

rm -rf "$XDG_DEST_DIR" "$SKEL_DEST_DIR" "$PROFILE_D_DIR" "$SSH_DEST_DIR" "./etc/zsh"
mkdir -p "$XDG_DEST_DIR" "$SKEL_DEST_DIR" "$PROFILE_D_DIR" "$SSH_DEST_DIR" "./etc/zsh"

if [ ! -d "$REPO_DIR" ]; then
    export CI=true DEBIAN_FRONTEND=noninteractive GIT_TERMINAL_PROMPT=0 GCM_INTERACTIVE=never HOMEBREW_NO_AUTO_UPDATE=1 GIT_EDITOR=: EDITOR=: VISUAL='' GIT_SEQUENCE_EDITOR=: GIT_MERGE_AUTOEDIT=no GIT_PAGER=cat PAGER=cat npm_config_yes=true PIP_NO_INPUT=1 YARN_ENABLE_IMMUTABLE_INSTALLS=false; git clone https://github.com/frieser/dotfiles "$REPO_DIR"
else
    cd "$REPO_DIR" && git pull && cd -
fi

for item in "$REPO_DIR"/*; do
    [ -e "$item" ] || continue
    process_item "$item" ""
done
