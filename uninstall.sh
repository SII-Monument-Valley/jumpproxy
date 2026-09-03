#!/bin/sh

set -u

DOMAIN="gui/$(/usr/bin/id -u)"
COMMAND="$HOME/.local/bin/jumpproxy"
INSTALL_ROOT="$HOME/.local/lib/jumpproxy"
CONFIG_ROOT="${XDG_CONFIG_HOME:-$HOME/.config}/jumpproxy"
STATE_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/jumpproxy"
AGENT_DIR="$HOME/Library/LaunchAgents"

if test -x "$COMMAND"; then
    "$COMMAND" off || true
fi

for config in "$CONFIG_ROOT/hosts"/*.conf; do
    test -e "$config" || continue
    basename=${config##*/}
    host=${basename%.conf}
    /bin/rm -f "$AGENT_DIR/com.jumpproxy.tunnel.$host.plist"
done
/bin/rm -f "$AGENT_DIR/com.jumpproxy.healthcheck.plist"
/bin/rm -rf "$INSTALL_ROOT"
/bin/rm -f "$COMMAND"

for shim in /opt/homebrew/bin/jumpproxy /usr/local/bin/jumpproxy; do
    if test -L "$shim" && test "$(/usr/bin/readlink "$shim")" = "$COMMAND"; then
        /bin/rm -f "$shim"
    fi
done

if test "${1:-}" = "--purge"; then
    /bin/rm -rf "$CONFIG_ROOT" "$STATE_ROOT" "$HOME/Library/Logs/jumpproxy"
    /bin/echo "Uninstalled jumpproxy manager and purged its configuration."
else
    /bin/echo "Uninstalled jumpproxy manager; host configuration was preserved in $CONFIG_ROOT."
fi
