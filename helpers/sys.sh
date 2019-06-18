#!/usr/bin/env bash
# General system helpers

# Execute a command as root (or sudo)
function do_with_root()
{
    # already root? "Just do it" (tm).
    if [[ $(whoami) = 'root' ]]; then
        bash -c "$@"
    elif [[ -x /bin/sudo || -x /usr/bin/sudo ]]; then
        echo "sudo $*"
        sudo bash -c "$@"
    else
        echo "This script must be run as root." >&2
        exit 1
    fi
}
