#!/usr/bin/env bash
set -euo pipefail

printf 'Removing yazi binaries from %s...\n' "$HOME/.local/bin"

removed=()
not_found=()
for name in yazi ya update-yazi; do
  target="$HOME/.local/bin/$name"
  if [ -e "$target" ]; then
    rm -f -- "$target"
    removed+=("$target")
  else
    not_found+=("$target")
  fi
done

if [ "${#removed[@]}" -gt 0 ]; then
  printf 'Removed: %s\n' "${removed[*]}"
fi
if [ "${#not_found[@]}" -gt 0 ]; then
  printf 'Not found (nothing to do): %s\n' "${not_found[*]}"
fi

# Only bash and zsh accept the function y() syntax used in the installer
# as-is; mirrors the shell detection from install-yazi.sh.
shell_name="$(basename "${SHELL:-}")"
case "$shell_name" in
  bash) rc_file="$HOME/.bashrc" ;;
  zsh) rc_file="$HOME/.zshrc" ;;
  *) rc_file="" ;;
esac

path_export='export PATH="$HOME/.local/bin:$PATH"'

if [ -n "$rc_file" ]; then
  if [ -f "$rc_file" ]; then
    printf 'Cleaning up %s...\n' "$rc_file"
    tmp_rc="$(mktemp)"
    trap 'rm -f "$tmp_rc"' EXIT
    # grep -vxF returns exit code 1 if no line matches the pattern, or if
    # nothing remains after filtering; this is not an error here, but the
    # normal case (PATH line already removed or never present).
    sed '/^function y() {$/,/^}$/d' "$rc_file" | { grep -vxF "$path_export" || true; } > "$tmp_rc"
    cp -- "$tmp_rc" "$rc_file"
    printf 'y() wrapper and PATH line removed from %s (if present).\n' "$rc_file"
  else
    printf 'Note: %s does not exist, nothing to clean up.\n' "$rc_file"
  fi
else
  printf 'Warning: shell "%s" is not cleaned up automatically (only bash and zsh are supported).\n' "${shell_name:-unknown}" >&2
  printf 'Please remove the y() function and the PATH line manually from the shell configuration file.\n' >&2
fi
