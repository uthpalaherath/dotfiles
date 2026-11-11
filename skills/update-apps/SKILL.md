---
name: update-apps
description: Check and update the user's self-installed CLI tools (starship, lazygit, delta, dust, bat, ripgrep, btop, yazi, git-lfs, navi, tealdeer, fzf, uv, rclone, tmux, vim, xclip) on DCC, NCShare, or another cluster. Use when asked to update apps/tools or check for new versions.
disable-model-invocation: true
---

# Update self-installed apps on a cluster

Arguments: an optional cluster (`dcc`, `ncshare`) and/or tool names, e.g., `/update-apps ncshare tmux vim`. With no tools named, cover every tool below that is installed on the target.

## Where to run

- Running on the target cluster's compute node (check `hostname`): run commands directly.
- On a login node (`*login*`), or on the Mac, or targeting a different cluster than the current host: run each command through the agent alias, `ssh dcc-agent '<cmd>'` or `ssh ncshare-agent '<cmd>'`. Never run anything on a login node.
- If the alias is missing (as on DCC itself, where `~/.ssh/config` has no agent aliases), say the target is unreachable from here and stop.
- NCShare agent jobs have a 1-hour wall time, so run one source build per ssh command instead of chaining them all together.

## Procedure

1. Find each tool on the target: `bash -ic 'p=$(command -v TOOL) && readlink -f "$p"'`. Use the interactive shell because `~/.bashrc` (-> `~/dotfiles/locations/<cluster>/.bashrc`) sets the PATH, and the `apps/` entries there come before `~/.local/bin`. Install the update over the path it resolves to. Copying it elsewhere would leave it shadowed. Skip tools that aren't installed and list them. Install new tools only on request.
2. Check before touching anything. Get the installed version (version command in the table) and the latest tag (`curl -fsSL https://api.github.com/repos/<repo>/releases/latest | jq -r .tag_name`). Show one compact table: tool, path, installed, latest. Then update only what's outdated, unless the user asked for a check only.
3. Download and build in a fresh `mktemp -d` dir, never inside the install locations. Pick `x86_64-unknown-linux-musl` assets when a release has them.
4. Install binaries atomically: `install -m755 new dest.new && mv -f dest.new dest`. Running processes keep the old inode and avoid ETXTBSY.
5. If a tool sits in a dir whose name carries a version (e.g., NCShare's `apps/ripgrep-14.1.1-x86_64-unknown-linux-musl/`), install the new version as a sibling dir with its own name. Then show the user the one-line PATH change for `~/dotfiles/locations/<cluster>/.bashrc` rather than editing it.
6. Verify each update with its version command. Report what changed in a few lines, and report failures with the relevant error output.

Don't stage or commit anything.

## Tools

| Tool | Repo | Version cmd | Method |
|---|---|---|---|
| starship | starship/starship | `--version` | release tarball, copy binary |
| lazygit | jesseduffield/lazygit | `--version` | `lazygit_*_linux_x86_64.tar.gz` |
| delta | dandavison/delta | `--version` | release tarball |
| dust | bootandy/dust | `--version` | release tarball |
| navi | denisidoro/navi | `--version` | release tarball |
| git-lfs | git-lfs/git-lfs | `--version` | `git-lfs-linux-amd64-v*.tar.gz` |
| tealdeer | tealdeer-rs/tealdeer | `tldr --version` | raw asset `tealdeer-linux-x86_64-musl` saved as `tldr`, then `tldr --update` |
| bat | sharkdp/bat | `--version` | extracted tarball dir replaces the install dir as a whole |
| ripgrep | BurntSushi/ripgrep | `rg --version` | same as bat |
| btop | aristocratos/btop | `--version` | see below |
| yazi | sxyazi/yazi | `--version` | `yazi-x86_64-unknown-linux-musl.zip`, copy `yazi` and `ya` |
| fzf | junegunn/fzf | `--version` | `git -C ~/.fzf pull --ff-only && ~/.fzf/install --bin` |
| uv | astral-sh/uv | `--version` | `uv self update`, then `uv tool upgrade --all` (ruff etc.) |
| rclone | rclone/rclone | `version` | `rclone selfupdate --stable` |
| tmux | tmux/tmux | `-V` | source build, see below |
| vim | vim/vim (tags) | `--version` | source build, see below |
| xclip | astrand/xclip (tags) | `-version` | git checkout: checkout latest tag, `./bootstrap && ./configure --prefix=<checkout>/build && make && make install` |

Claude Code updates itself, so leave it out. The science codes under `apps/` (QE, SIESTA, FHI-aims, ELPA, netCDF, VASP, wannier90, R, etc.) are also out of scope unless the user names one.

## Known layouts

DCC (`APPS=/hpc/group/rescomp/ukh/apps`, `BIN=~/.local/bin`), as of 2026-11:
starship, lazygit, delta, dust, navi, git-lfs, tldr and tmux are in `$BIN`. btop is a `$BIN` symlink to `$APPS/btop-X.Y.Z/bin/btop`. bat is `$APPS/bat/`, ripgrep is `$APPS/ripgrep/`, yazi is `$APPS/yazi/target/release/`, vim is `$APPS/vim-local` (prefix install), and xclip is `$APPS/xclip/build/bin` (git checkout in `$APPS/xclip`).

NCShare: apps are under `~/apps` (from `.bashrc`, not yet verified on the machine). ripgrep is `~/apps/ripgrep-14.1.1-x86_64-unknown-linux-musl/` (versioned, see step 5), bat is `~/apps/bat`, yazi is `~/apps/yazi/target/release`, vim is `~/apps/vim`. Use the discovery step for the rest. Once you've verified the layout, update this section.

## Source-build notes

These were worked out on DCC. On another cluster, first check the existing build's `--version` output and the prerequisites, then adapt.

btop: install the new version into `<apps>/btop-X.Y.Z/` (`bin/btop` plus `share/btop/themes/` taken from the tarball's `themes/`), then `ln -sfn` the existing symlink to it. If btop is a plain binary rather than a symlink, replace it atomically and copy themes to `../share/btop/themes` next to it. Tell the user the old `btop-*` dir can be deleted. Don't delete it yourself.

tmux: build against the static libevent and ncurses in `~/.local` from `~/dotfiles/setups/tmux_setup_noroot.sh`. If they're missing, run that script's libevent/ncurses steps first.
```
PKG_CONFIG_PATH=~/.local/lib/pkgconfig ./configure \
  CFLAGS="-I$HOME/.local/include -I$HOME/.local/include/ncurses" LDFLAGS="-L$HOME/.local/lib"
make -j
```
Afterward, warn the user that running tmux servers keep the old version. They need `tmux kill-server` before new clients will attach.

vim: the latest tag is `git ls-remote --tags --refs https://github.com/vim/vim.git | sed 's#.*refs/tags/##' | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -1`. The installed version is line 1's version plus the max of "Included patches" (e.g., 9.2.0424). Use the existing install's prefix (the parent of its `bin/`). Shallow-clone the tag and build in `src/`:
- If configure finds no terminal library (DCC has no `libtinfo.so` dev symlink), use `--with-tlib=ncurses` with `CPPFLAGS=-I$HOME/.local/include LDFLAGS=-L$HOME/.local/lib`.
- Python 3 comes from conda/miniforge. Its sysconfig names the static `libpython3.X.a`, so configure disables Python or bakes in a bad dlopen name. Pass `vi_cv_dll_name_python3=<LIBDIR>/libpython3.X.so` in the environment, `--with-python3-command=$(command -v python3)`, and add `-L<LIBDIR>` to LDFLAGS. Get LIBDIR from `python3 -c 'import sysconfig; print(sysconfig.get_config_var("LIBDIR"))'`. This fix is not yet verified end to end.
- Full flags: `--prefix=<prefix> --with-features=huge --enable-python3interp=dynamic --with-x --enable-gui=no --enable-terminal`.
- Before installing, check that `./vim --version` keeps every `+feature` the current build has (at least `+clipboard +python3/dyn +terminal`, and `+X11` if present now). If any is missing, stop and report. Otherwise `rm -f <prefix>/bin/vim && make install`.
- Run `vim -es -u NONE -c 'py3 print(1)' -c q` to confirm Python loads.
- Remind the user that plugins update separately with `:PlugUpdate`.

If a source build fails, leave the existing install alone and report the error.
