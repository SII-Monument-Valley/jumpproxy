#!/bin/sh

set -eu

PROJECT_DIR=$(CDPATH= cd -- "$(/usr/bin/dirname -- "$0")" && /bin/pwd)
INSTALL_ROOT="$HOME/.local/lib/jumpproxy"
USER_BIN="$HOME/.local/bin"
COMMAND="$USER_BIN/jumpproxy"
HOSTS_FILE="$PROJECT_DIR/hosts.tsv"

if test "$(/usr/bin/uname -s)" != "Darwin"; then
    /bin/echo "This installer requires macOS launchd." >&2
    exit 1
fi

/usr/bin/install -d -m 755 "$INSTALL_ROOT" "$USER_BIN"
/usr/bin/install -m 755 "$PROJECT_DIR/bin/jumpproxy" "$COMMAND"
/usr/bin/install -m 755 "$PROJECT_DIR/libexec/jumpproxy-tunnel" "$INSTALL_ROOT/jumpproxy-tunnel"
/usr/bin/install -m 755 "$PROJECT_DIR/libexec/jumpproxy-healthcheck" "$INSTALL_ROOT/jumpproxy-healthcheck"

"$COMMAND" _install-healthcheck

SHIM=""
for candidate_dir in /opt/homebrew/bin /usr/local/bin; do
    if test -d "$candidate_dir" && test -w "$candidate_dir"; then
        /bin/ln -sf "$COMMAND" "$candidate_dir/jumpproxy"
        SHIM="$candidate_dir/jumpproxy"
        break
    fi
done

if test "${1:-}" != "--no-hosts" && test -r "$HOSTS_FILE"; then
    tab=$(/usr/bin/printf '\t')
    while IFS="$tab" read -r host ssh_user remote_port local_port ssh_config; do
        case "$host" in ''|'#'*) continue ;; esac
        if test "$ssh_user" = "-" && { test -z "$ssh_config" || test "$ssh_config" = "-"; }; then
            "$COMMAND" add "$host" --remote-port "$remote_port" --local-port "$local_port"
        elif test "$ssh_user" = "-"; then
            "$COMMAND" add "$host" --remote-port "$remote_port" --local-port "$local_port" --ssh-config "$ssh_config"
        elif test -z "$ssh_config" || test "$ssh_config" = "-"; then
            "$COMMAND" add "$host" --user "$ssh_user" --remote-port "$remote_port" --local-port "$local_port"
        else
            "$COMMAND" add "$host" --user "$ssh_user" --remote-port "$remote_port" --local-port "$local_port" --ssh-config "$ssh_config"
        fi
    done < "$HOSTS_FILE"
fi

# Recreate missing plists for any registry entries preserved from an earlier
# installation, including hosts not present in this project's hosts.tsv.
"$COMMAND" on

/bin/echo
/bin/echo "Installed jumpproxy manager."
if test -n "$SHIM"; then
    /bin/echo "Command: $SHIM"
else
    /bin/echo "Add $USER_BIN to PATH, then run: jumpproxy status"
fi
