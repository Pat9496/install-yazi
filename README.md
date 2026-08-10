# yazi Installer

Automatic installation script for the [yazi](https://github.com/sxyazi/yazi) terminal file manager on Linux. The script downloads the latest yazi release, installs the binaries into `$HOME/.local/bin`, and optionally sets up a shell wrapper that changes directory on exit.

## Requirements

The script requires the following programs to be installed beforehand:

- `curl` — to download the release assets
- `unzip` — to unpack the downloaded archive
- Linux kernel (macOS, Windows, and other operating systems are not supported)

The script automatically checks for `curl` and `unzip` and aborts with a clear error message if either is missing.

## Installation

Run the script directly:

```bash
bash install-yazi.sh
```

The script works without root privileges and stores all files in `$HOME/.local/bin`. After a successful installation, the `yazi` and `ya` commands are available.

If the shell integration succeeded, a new shell session must be started, or the configuration file (`.bashrc` or `.zshrc`) must be reloaded, for the changes to take effect.

## Usage

After installation, yazi can be started in two ways:

- `yazi` — opens the yazi file manager directly
- `y` — opens yazi with automatic directory change on exit (see the Shell Integration section)

The `yazi` and `ya` binaries are located in `$HOME/.local/bin` and are automatically added to `PATH` (provided shell integration succeeded).

## Shell Integration

The script sets up a shell wrapper `y()` that starts yazi and, on exit, automatically changes into the directory yazi last displayed. This is the installer's main advantage over a manual installation.

### Bash and Zsh

For Bash and Zsh, integration happens automatically:

1. A `y()` function is added to `$HOME/.bashrc` (for Bash) or `$HOME/.zshrc` (for Zsh).
2. The `PATH` variable is extended with `$HOME/.local/bin`.
3. If the entries already exist, they are not duplicated.

### Other Shells (Fish, Dash, Csh, etc.)

For other shells, the script cannot perform the integration automatically. Instead, it prints a warning with the required lines:

```
export PATH="$HOME/.local/bin:$PATH"

function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    command yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
    command rm -f -- "$tmp"
}
```

These lines must be added manually to the shell's configuration file. The exact file varies by shell (e.g. `~/.config/fish/config.fish` for Fish).

## Updating

After installation, a script `$HOME/.local/bin/update-yazi` is provided, which can be used later to perform an update:

```bash
update-yazi
```

The update script performs the same architecture and libc detection as the original installer, and downloads and installs the latest yazi release.

## Supported Architectures

The script supports all architectures for which yazi provides release assets:

- `x86_64` — with automatic glibc/musl detection
- `aarch64` (ARM64) — with automatic glibc/musl detection
- `i686` — glibc only
- `riscv64gc` — glibc only
- `sparc64` — glibc only

If the system architecture is not supported, the script shows a clear error message and exits without making any changes.

### LibC Detection

The script automatically detects whether the system uses glibc or musl as its C library. Musl builds of yazi exist for `x86_64` and `aarch64`; for all other architectures, the glibc variant is used automatically.

## Error Handling

The script checks all prerequisites before running:

- Linux kernel
- Availability of `curl` and `unzip`
- Supported CPU architecture
- Successful download and extraction of the yazi archive

If any of these steps fail, the script shows a clear error message and exits with exit code 1 without modifying the system.

## Uninstallation

Run `uninstall-yazi.sh` to remove the installed binaries (`yazi`, `ya`, `update-yazi`) from `$HOME/.local/bin` and clean up the `y()` wrapper and `PATH` line from `.bashrc`/`.zshrc`:

```bash
bash uninstall-yazi.sh
```

## Credits

This installer is a third-party convenience script and is not affiliated with or endorsed by the yazi project. All credit for yazi itself goes to [sxyazi](https://github.com/sxyazi) and the [yazi contributors](https://github.com/sxyazi/yazi/graphs/contributors). The `y()` shell wrapper pattern used for directory-change-on-exit follows the approach documented in [yazi's own quick-start guide](https://yazi-rs.github.io/docs/quick-start).

## License

This installer script is released under the [MIT License](LICENSE). yazi itself is distributed under its own license — see the [yazi repository](https://github.com/sxyazi/yazi) for details.
