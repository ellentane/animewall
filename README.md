# animewall

Wallhaven wallpaper libraries for illogical-impulse on Hyprland. A timer switches the wallpaper every few minutes, and a panel in the bar picks what rotates.

## What's in here

- `animewall` is the CLI that does the work: downloads, rotation, favorites, bans and the timer. With no command it prints the state, and `animewall help` lists the commands.
- `systemd/`: `animewall.timer` runs `animewall.service`, which is `animewall next`, every 5 minutes. `animewall-fetch.service` downloads in the background.
- `quickshell/`: the panel and the service that runs the CLI for it, at their paths under `~/.config/quickshell/ii`.
- `patches/`: changes to illogical-impulse's own files, made against end-4/dots-hyprland 6eb590b1.
  - `panel.patch` adds the panel's open state and its loader.
  - `bar-button.patch` adds the bar button and the `bar.utilButtons.showAnimewall` option.
  - `no-prompts.patch` lets animewall turn off switchwall's upscale prompt.
  - `prompt-timeout.patch` gives switchwall's prompts five minutes.
  - `terminal-sequences.patch` closes the last OSC in the terminal color template. Without it every wallpaper change left TUIs like cc and codex drawing nothing.

## Install

    ./install.sh

It links the CLI, the units and the panel files from the repo into place, so a change here is live at once, and applies each patch that is not in yet. A different file already where a link goes is kept beside it as `*.before-install`. An ii update overwrites the patched files, so run it again after one.

## Where the rest lives

- `~/.config/animewall/config.toml`: the settings, written on first run. It holds the Wallhaven API key, which NSFW needs, so it stays out of the repo.
- `~/.local/state/animewall`: the selection, the shuffled bags, rejected ids and banned files.
- `~/Pictures/Wallpapers/{anime,other,favorites}`: the libraries, one folder per purity.
- `~/.config/systemd/user/animewall.timer.d/interval.conf`: written by `animewall interval`.
