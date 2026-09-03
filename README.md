# jumpproxy-manager

Portable macOS `launchd` manager for persistent Cloudflare Access SSH reverse
proxies. It contains no machine-specific username or home-directory path.

Each registered host receives its own LaunchAgent. By default, the remote host's
`127.0.0.1:1080` is forwarded to the Mac's `127.0.0.1:7897`. A separate health
check runs every 60 seconds and restarts a tunnel after two failed checks.

## Install on a new Mac

Prerequisites:

- `cloudflared` is installed.
- An SSH key exists at `~/.ssh/id_rsa` or `~/.ssh/id_ed25519`.
- The public key is authorized on each remote host.
- The local HTTP or mixed proxy listens on port 7897.

Run:

```sh
./install.sh
```

The hosts listed in `hosts.tsv` are installed and connected immediately. To
install the manager without that list, run `./install.sh --no-hosts`.

## Commands

```sh
jumpproxy add example.com
jumpproxy add example.com --user ubuntu --remote-port 1080 --local-port 7897
jumpproxy modify example.com --remote-port 1081
jumpproxy modify example.com --local-port 7898
jumpproxy remove example.com

jumpproxy defaults
jumpproxy defaults --remote-port 1080 --local-port 7897
jumpproxy defaults --reset

jumpproxy disable example.com
jumpproxy enable example.com
jumpproxy restart example.com

jumpproxy off
jumpproxy on
jumpproxy restart
jumpproxy status
jumpproxy status example.com
jumpproxy list
jumpproxy help
jumpproxy help add
jumpproxy help modify
jumpproxy help defaults
```

`add` accepts a server-side listening port with `--remote-port` and a Mac-side
proxy port with `--local-port`. When either option is omitted, its persisted
value from `jumpproxy defaults` is used. Built-in defaults are remote `1080`
and local `7897`.

`modify` (alias `update`) changes an existing host. Any option not supplied is
kept unchanged; the corresponding LaunchAgent is regenerated and reconnected
automatically.

`disable` persists across logout and reboot. It unloads the LaunchAgent and
terminates only the process tree captured from that job, so unrelated SSH and
Codex sessions are not selected. `enable` loads the job and immediately asks
launchd to connect. `KeepAlive` handles later disconnects.

New SSH host keys use OpenSSH's `accept-new` policy: unseen keys are recorded,
while a changed key is rejected.

## Files installed

- `~/.local/bin/jumpproxy`
- `~/.local/lib/jumpproxy/`
- `~/.config/jumpproxy/hosts/`
- `~/Library/LaunchAgents/com.jumpproxy.*.plist`
- `~/Library/Logs/jumpproxy/`

When writable, the installer also creates a `jumpproxy` symlink in
`/opt/homebrew/bin` or `/usr/local/bin`.

## Uninstall

```sh
./uninstall.sh          # preserve the host registry
./uninstall.sh --purge  # also remove registry, state, and logs
```
