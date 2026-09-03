# jumpproxy-manager

Portable macOS `launchd` manager for persistent SSH reverse proxies. It
contains no machine-specific username or home-directory path, and it has no
direct dependency on `cloudflared`.

Each registered host receives its own LaunchAgent. By default, the remote host's
`127.0.0.1:1080` is forwarded to the Mac's `127.0.0.1:7897`. A separate health
check runs every 60 seconds and restarts a tunnel after two failed checks.

## Install on a new Mac

Prerequisites:

- The target host can be reached non-interactively using the selected SSH
  config (default: `~/.ssh/config`).
- The local HTTP or mixed proxy listens on port 7897.

All connection settings—including `HostName`, `User`, `Port`, `IdentityFile`,
`ProxyJump`, and `ProxyCommand`—come from the SSH config. If that config uses
Cloudflare Access, then `cloudflared` is naturally required by the config; the
jumpproxy service itself neither locates nor invokes it directly.

Tunnel jobs disable SSH connection multiplexing for their own process so that
stopping one managed tunnel never terminates or takes ownership of an unrelated
interactive SSH/Codex control connection. All routing and authentication
settings still come from the selected SSH config.

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
jumpproxy add my-alias --ssh-config ~/.ssh/work-config
jumpproxy modify example.com --remote-port 1081
jumpproxy modify example.com --local-port 7898
jumpproxy modify example.com --ssh-config ~/.ssh/another-config
jumpproxy modify example.com --user -  # clear override; use User from config
jumpproxy remove example.com

jumpproxy defaults
jumpproxy defaults --remote-port 1080 --local-port 7897 --ssh-config ~/.ssh/config
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

`add` accepts a server-side listening port with `--remote-port`, a Mac-side
proxy port with `--local-port`, and an SSH config with `--ssh-config`. When an
option is omitted, its persisted value from `jumpproxy defaults` is used.
Built-in defaults are remote `1080`, local `7897`, and `~/.ssh/config`.

The SSH user is read from the SSH config by default. `--user USER` overrides
it for one registration; `--user -` clears a previous override.

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
- `~/.config/jumpproxy/defaults.conf`
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
