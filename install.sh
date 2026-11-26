#!/usr/bin/env bash
# Puts animewall in place from this repo: links the CLI, the systemd units and the panel
# files, and patches illogical-impulse's own files. A second run changes nothing, so this
# is also how the patches come back after an ii update overwrites them.
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
config=${XDG_CONFIG_HOME:-$HOME/.config}
ii=$config/quickshell/ii
units=$config/systemd/user

# link <path in the repo> <where it goes>; a different file already there is kept beside it
link() {
    local src=$repo/$1 dest=$2
    mkdir -p "$(dirname "$dest")"
    if [[ -e $dest && ! -L $dest ]] && ! cmp -s "$src" "$dest"; then
        mv "$dest" "$dest.before-install"
        echo "kept the old $dest as $dest.before-install"
    fi
    ln -sfn "$src" "$dest"
    echo "linked $dest"
}

link animewall "$HOME/.local/bin/animewall"
for unit in "$repo"/systemd/*; do
    link "systemd/${unit##*/}" "$units/${unit##*/}"
done
while read -r f; do
    link "quickshell/$f" "$ii/$f"
done < <(cd "$repo/quickshell" && find . -type f -printf '%P\n')

# each patch once: one that reverses cleanly is already in
status=0
for p in "$repo"/patches/*.patch; do
    name=${p##*/}
    if patch -d "$ii" -p1 -R -s -f --dry-run <"$p" >/dev/null 2>&1; then
        echo "already applied: $name"
    elif patch -d "$ii" -p1 -N -s -f --dry-run <"$p" >/dev/null 2>&1; then
        patch -d "$ii" -p1 -N -s -f --no-backup-if-mismatch <"$p"
        echo "applied: $name"
    else
        echo "does not apply, ii changed under it: $name" >&2
        status=1
    fi
done

systemctl --user daemon-reload
# only the first install starts the rotation, so a paused one stays paused
if [[ ! -e $units/timers.target.wants/animewall.timer ]]; then
    systemctl --user enable --now animewall.timer
fi
exit $status
