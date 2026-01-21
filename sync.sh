#!/bin/bash

REPO_DIR="/tmp/dotfiles-repo"
XDG_DEST_DIR="./etc"
XDG_CONFIG_DIR="./etc/xdg"
PROFILE_D_DIR="./etc/profile.d"
SSH_DEST_DIR="./etc/ssh"
USR_SHARE_DIR="./usr/share"
USR_BIN_DIR="./usr/bin"

mkdir -p "$XDG_DEST_DIR"
mkdir -p "$XDG_CONFIG_DIR"
mkdir -p "$PROFILE_D_DIR"
mkdir -p "$SSH_DEST_DIR"
mkdir -p "$USR_SHARE_DIR"
mkdir -p "$USR_BIN_DIR"

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

    local target_root="$XDG_CONFIG_DIR"
    local final_name="$new_base"
    
    if [ -z "$relative_path" ]; then
        case "$new_base" in
            ".zshrc")
                target_root="$XDG_DEST_DIR"
                final_name="zshrc"
                ;;
            ".bashrc")
                target_root="$PROFILE_D_DIR"
                final_name="99-global-bashrc.sh"
                ;;
            ".ssh")
                target_root="$SSH_DEST_DIR"
                final_name="ssh_config.d"
                ;;
            "keyd"|"niri"|"nushell"|"systemd"|"tmux"|"udev"|"pam.d"|"sddm"|"sddm.conf.d"|"plymouth"|"libinput")
                target_root="$XDG_DEST_DIR"
                ;;
            "share")
                target_root="./usr"
                ;;
            "bin")
                target_root="./usr"
                ;;
            "quickshell"|".quickshell")
                target_root="$XDG_CONFIG_DIR"
                final_name="quickshell"
                ;;
            *)
                if [[ "$new_base" == .* ]]; then
                    target_root="$XDG_CONFIG_DIR"
                    final_name="${new_base#.}"
                fi
                ;;
        esac
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
            
            process_item_recursive "$subitem" "" "$new_path" 
        done
        find "$new_path" -name ".git" -exec rm -rf {} +
        find "$new_path" -name ".gitmodules" -exec rm -f {} +
    else
        mkdir -p "$(dirname "$new_path")"
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
    new_path="${new_path//\/\//\/}"

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

rm -rf "$PROFILE_D_DIR" "$SSH_DEST_DIR" "./etc/zshrc"
rm -rf "$XDG_CONFIG_DIR"

mkdir -p "$XDG_DEST_DIR" "$XDG_CONFIG_DIR" "$PROFILE_D_DIR" "$SSH_DEST_DIR" "$USR_SHARE_DIR"

if [ ! -d "$REPO_DIR" ]; then
    export CI=true DEBIAN_FRONTEND=noninteractive GIT_TERMINAL_PROMPT=0 GCM_INTERACTIVE=never HOMEBREW_NO_AUTO_UPDATE=1 GIT_EDITOR=: EDITOR=: VISUAL='' GIT_SEQUENCE_EDITOR=: GIT_MERGE_AUTOEDIT=no GIT_PAGER=cat PAGER=cat npm_config_yes=true PIP_NO_INPUT=1 YARN_ENABLE_IMMUTABLE_INSTALLS=false; git clone https://github.com/frieser/dotfiles "$REPO_DIR"
else
    cd "$REPO_DIR" && git pull && cd -
fi

if [ -f "$REPO_DIR/dot_config/quickshell" ] || [ -d "$REPO_DIR/dot_config/quickshell" ] || [ -f "$REPO_DIR/dot_quickshell" ] || [ -d "$REPO_DIR/dot_quickshell" ] || [ -d "$REPO_DIR/quickshell" ]; then
    echo "Quickshell configuration found."
else
    echo "WARNING: Quickshell configuration NOT found in repository."
fi

for item in "$REPO_DIR"/*; do
    [ -e "$item" ] || continue
    process_item "$item" ""
done

SPAWN_KDL="$XDG_DEST_DIR/niri/spawn.kdl"
if [ -f "$SPAWN_KDL" ]; then
    sed -i 's|spawn-sh-at-startup "QML_IMPORT_PATH=.*quickshell"|spawn-sh-at-startup "QML_IMPORT_PATH=/usr/lib64/qt6/qml LD_LIBRARY_PATH=/usr/lib64/qt6/qml/Niri uwsm app -- quickshell > /tmp/quickshell-spawn.log 2>\&1"|' "$SPAWN_KDL"
fi
