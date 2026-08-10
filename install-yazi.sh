#!/usr/bin/env bash
set -euo pipefail

# This script is deliberately restricted to Linux, since its core purpose is
# the .bashrc/.zshrc-integrated y() wrapper, which does not fit macOS/Windows.
if [ "$(uname -s)" != "Linux" ]; then
  printf 'Error: this script only supports Linux (detected: %s)\n' "$(uname -s)" >&2
  exit 1
fi

reinstall=0
for arg in "$@"; do
  case "$arg" in
    --reinstall) reinstall=1 ;;
    *)
      printf 'Error: unknown option "%s"\n' "$arg" >&2
      exit 1
      ;;
  esac
done

missing=()
for cmd in curl unzip; do
  command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done
if [ "${#missing[@]}" -gt 0 ]; then
  printf 'Error: required programs are missing: %s\n' "${missing[*]}" >&2
  exit 1
fi

mkdir -p "$HOME/.local/bin"

# uname -m does not always return the name yazi uses for its release assets
# (e.g. riscv64 -> riscv64gc), hence the explicit mapping.
map_asset_arch() {
  case "$1" in
    x86_64) printf 'x86_64\n' ;;
    aarch64|arm64) printf 'aarch64\n' ;;
    i686|i586|i486|i386) printf 'i686\n' ;;
    riscv64) printf 'riscv64gc\n' ;;
    sparc64) printf 'sparc64\n' ;;
    *) return 1 ;;
  esac
}

# On musl systems, ldd --version prints "musl libc" to stderr, but exits
# with a non-zero exit code. The output must therefore first be captured
# into a variable (exit code neutralized via "|| true"), otherwise the
# pipeline would, because of pipefail, incorrectly report ldd's exit code
# instead of the grep match.
detect_libc() {
  local ldd_output
  if command -v ldd >/dev/null 2>&1; then
    ldd_output="$(ldd --version 2>&1 || true)"
    if printf '%s' "$ldd_output" | grep -qi musl; then
      printf 'musl\n'
      return
    fi
  fi
  printf 'gnu\n'
}

if [ "$reinstall" -eq 1 ] || [ ! -x "$HOME/.local/bin/yazi" ]; then
  printf 'Detecting architecture and libc...\n'
  arch_raw="$(uname -m)"
  if ! asset_arch="$(map_asset_arch "$arch_raw")"; then
    printf 'Error: architecture "%s" is not supported by yazi (no release asset available)\n' "$arch_raw" >&2
    exit 1
  fi

  libc="$(detect_libc)"
  # Only x86_64/aarch64 have musl builds; all other architectures only have
  # gnu builds, so always use gnu there.
  case "$asset_arch" in
    x86_64|aarch64) libc_suffix="$libc" ;;
    *) libc_suffix="gnu" ;;
  esac
  printf 'Architecture: %s (asset: %s), libc: %s\n' "$arch_raw" "$asset_arch" "$libc_suffix"

  zip_name="yazi-${asset_arch}-unknown-linux-${libc_suffix}.zip"
  printf 'Release file: %s\n' "$zip_name"

  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT

  download_url="https://github.com/sxyazi/yazi/releases/latest/download/${zip_name}"
  printf 'Downloading yazi: %s\n' "$download_url"
  curl -fL "$download_url" \
    -o "$TMP/yazi.zip"
  printf 'Download complete, extracting archive...\n'
  unzip -q "$TMP/yazi.zip" -d "$TMP"

  yazi_bin="$(find "$TMP" -type f -name yazi | head -1)"
  ya_bin="$(find "$TMP" -type f -name ya | head -1)"
  if [ -z "$yazi_bin" ] || [ -z "$ya_bin" ]; then
    printf 'Error: yazi/ya binaries were not found in the extracted archive. Contents of %s:\n' "$TMP" >&2
    find "$TMP" >&2 || true
    exit 1
  fi

  printf 'Installing binaries to %s...\n' "$HOME/.local/bin"
  install -Dm755 "$yazi_bin" "$HOME/.local/bin/yazi"
  install -Dm755 "$ya_bin" "$HOME/.local/bin/ya"
  printf 'yazi and ya installed to %s\n' "$HOME/.local/bin"
else
  printf 'yazi is already installed, skipping download (use --reinstall to force).\n'
fi

y_wrapper="$(cat <<'EOS'
function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    command yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
    command rm -f -- "$tmp"
}
EOS
)"
path_export='export PATH="$HOME/.local/bin:$PATH"'

# Only bash and zsh accept the function y() syntax used above as-is;
# other shells (e.g. fish) have incompatible function syntax.
shell_name="$(basename "${SHELL:-}")"
case "$shell_name" in
  bash) rc_file="$HOME/.bashrc" ;;
  zsh) rc_file="$HOME/.zshrc" ;;
  *) rc_file="" ;;
esac

if [ -n "$rc_file" ]; then
  touch "$rc_file"
  printf 'Updating %s...\n' "$rc_file"
  # Shell wrapper y(): changes to the last displayed directory after yazi exits
  if grep -q 'function y()' "$rc_file"; then
    printf 'y() wrapper already present in %s, not adding it again.\n' "$rc_file"
  else
    printf '\n%s\n' "$y_wrapper" >> "$rc_file"
    printf 'y() wrapper added to %s.\n' "$rc_file"
  fi
  if grep -qxF "$path_export" "$rc_file"; then
    printf 'PATH line already present in %s.\n' "$rc_file"
  else
    printf '%s\n' "$path_export" >> "$rc_file"
    printf 'PATH line added to %s.\n' "$rc_file"
  fi
else
  cat >&2 <<EOF
Warning: shell "${shell_name:-unknown}" is not configured automatically (only bash and zsh are supported).
Please add the following lines manually to the shell's configuration file:

$path_export

$y_wrapper
EOF
fi

# Update function: update-yazi
printf 'Writing update-yazi to %s...\n' "$HOME/.local/bin/update-yazi"
cat > "$HOME/.local/bin/update-yazi" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail

if [ "$(uname -s)" != "Linux" ]; then
  printf 'Error: this script only supports Linux (detected: %s)\n' "$(uname -s)" >&2
  exit 1
fi

missing=()
for cmd in curl unzip; do
  command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done
if [ "${#missing[@]}" -gt 0 ]; then
  printf 'Error: required programs are missing: %s\n' "${missing[*]}" >&2
  exit 1
fi

map_asset_arch() {
  case "$1" in
    x86_64) printf 'x86_64\n' ;;
    aarch64|arm64) printf 'aarch64\n' ;;
    i686|i586|i486|i386) printf 'i686\n' ;;
    riscv64) printf 'riscv64gc\n' ;;
    sparc64) printf 'sparc64\n' ;;
    *) return 1 ;;
  esac
}

detect_libc() {
  local ldd_output
  if command -v ldd >/dev/null 2>&1; then
    ldd_output="$(ldd --version 2>&1 || true)"
    if printf '%s' "$ldd_output" | grep -qi musl; then
      printf 'musl\n'
      return
    fi
  fi
  printf 'gnu\n'
}

printf 'Detecting architecture and libc...\n'
arch_raw="$(uname -m)"
if ! asset_arch="$(map_asset_arch "$arch_raw")"; then
  printf 'Error: architecture "%s" is not supported by yazi (no release asset available)\n' "$arch_raw" >&2
  exit 1
fi

libc="$(detect_libc)"
case "$asset_arch" in
  x86_64|aarch64) libc_suffix="$libc" ;;
  *) libc_suffix="gnu" ;;
esac
printf 'Architecture: %s (asset: %s), libc: %s\n' "$arch_raw" "$asset_arch" "$libc_suffix"

zip_name="yazi-${asset_arch}-unknown-linux-${libc_suffix}.zip"
printf 'Release file: %s\n' "$zip_name"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

download_url="https://github.com/sxyazi/yazi/releases/latest/download/${zip_name}"
printf 'Downloading yazi: %s\n' "$download_url"
curl -fL "$download_url" \
  -o "$TMP/yazi.zip"
printf 'Download complete, extracting archive...\n'
unzip -q "$TMP/yazi.zip" -d "$TMP"

yazi_bin="$(find "$TMP" -type f -name yazi | head -1)"
ya_bin="$(find "$TMP" -type f -name ya | head -1)"
if [ -z "$yazi_bin" ] || [ -z "$ya_bin" ]; then
  printf 'Error: yazi/ya binaries were not found in the extracted archive. Contents of %s:\n' "$TMP" >&2
  find "$TMP" >&2 || true
  exit 1
fi

printf 'Installing binaries to %s...\n' "$HOME/.local/bin"
install -Dm755 "$yazi_bin" "$HOME/.local/bin/yazi"
install -Dm755 "$ya_bin" "$HOME/.local/bin/ya"
printf 'yazi and ya installed to %s\n' "$HOME/.local/bin"
"$HOME/.local/bin/yazi" --version
EOS
chmod +x "$HOME/.local/bin/update-yazi"
printf 'update-yazi installed to %s\n' "$HOME/.local/bin/update-yazi"
