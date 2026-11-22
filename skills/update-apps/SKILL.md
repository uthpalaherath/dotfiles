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

1. Find each tool on the target: `env -i HOME=$HOME USER=$USER TERM=xterm bash -lic 'p=$(command -v TOOL) && readlink -f "$p"'`. The clean login shell matters because `~/.bashrc` (-> `~/dotfiles/locations/<cluster>/.bashrc`) builds the PATH, and an inherited PATH can still carry entries that `.bashrc` no longer sets. Also note whether `$BIN/TOOL` is a plain file or a symlink. If the tool resolves through a `.bashrc` PATH entry instead of `$BIN`, the cluster hasn't been migrated to the layout below, so offer the migration (see "Migrating a cluster") before updating. Skip tools that aren't installed and list them. Install new tools only on request.
2. Check before touching anything. Get the installed version (version command in the table) and the latest tag (`curl -fsSL https://api.github.com/repos/<repo>/releases/latest | jq -r .tag_name`). Show one compact table: tool, path, installed, latest. Then update only what's outdated, unless the user asked for a check only.
3. Download and build in a fresh `mktemp -d` dir, never inside the install locations. Pick `x86_64-unknown-linux-musl` assets when a release has them. The scratch dir can be cleaned between turns, so download again rather than reuse files from an earlier turn.
4. Single-binary tools are plain files in `$BIN`. Replace them atomically: `install -m755 new dest.new && mv -f dest.new dest`. Running processes keep the old inode and avoid ETXTBSY.
5. Multi-file tools live in `$APPS/<tool>-X.Y.Z/` with a `$BIN` symlink to the binary. Install the new version as a new sibling dir, check that the binary exists and runs from there, then `ln -sfn` the link to it. Tell the user the old dir can be deleted. Don't delete it yourself. No `.bashrc` edit is needed.
6. Chain dependent steps with `&&` and test that a file exists before linking to it or deleting anything. Don't rely on `set -e`: it didn't stop a script here after a failed `install`, and the script went on to remove the old install.
7. Verify each update with its version command. Report what changed in a few lines, and report failures with the relevant error output.

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
| bat | sharkdp/bat | `--version` | extracted tarball dir becomes `$APPS/bat-X.Y.Z/`, link `$BIN/bat` |
| ripgrep | BurntSushi/ripgrep | `rg --version` | extracted tarball dir becomes `$APPS/ripgrep-X.Y.Z/`, link `$BIN/rg` |
| btop | aristocratos/btop | `--version` | see below |
| yazi | sxyazi/yazi | `--version` | `yazi-x86_64-unknown-linux-musl.zip`, `yazi` and `ya` into `$APPS/yazi-X.Y.Z/`, link both |
| fzf | junegunn/fzf | `--version` | `git -C ~/.fzf pull --ff-only && ~/.fzf/install --bin` |
| uv | astral-sh/uv | `--version` | `uv self update`, then `uv tool upgrade --all` (ruff etc.). On DCC there is no install receipt, so self update fails: install `uv` and `uvx` from `uv-x86_64-unknown-linux-musl.tar.gz` instead |
| rclone | rclone/rclone | `version` | `rclone selfupdate --stable` |
| tmux | tmux/tmux | `-V` | source build, see below |
| vim | vim/vim (tags) | `--version` | source build, see below |
| xclip | astrand/xclip (tags) | `-version` | git checkout: checkout latest tag, `./bootstrap && ./configure --prefix=<checkout>/build && make && make install`. `$BIN/xclip` links to `build/bin/xclip`, so nothing to relink |

Claude Code updates itself, so leave it out. The science codes under `apps/` (QE, SIESTA, FHI-aims, ELPA, netCDF, VASP, wannier90, R, etc.) are also out of scope unless the user names one.

## Layout convention

Every tool in the table is reached through `$BIN` (`~/.local/bin`), which is the only PATH entry these tools need. Single binaries are plain files in `$BIN`. Tools that ship more than a binary (runtime files, themes, man pages, completions, a git checkout) keep their full install under `$APPS` and get a `$BIN` symlink. Never copy just the binary out of such a dir, because vim needs its runtime and btop its themes. The science codes keep their own `.bashrc` PATH entries.

## Known layouts

DCC (`APPS=/hpc/group/rescomp/ukh/apps`, `BIN=~/.local/bin`), migrated 2026-11-21:
- Plain files in `$BIN`: starship, lazygit, delta, dust, navi, git-lfs, tldr, tmux, uv, uvx, rclone.
- `$BIN` symlinks: `btop` -> `$APPS/btop-X.Y.Z/bin/btop`, `bat` -> `$APPS/bat-X.Y.Z/bat`, `rg` -> `$APPS/ripgrep-X.Y.Z/rg`, `yazi` and `ya` -> `$APPS/yazi-X.Y.Z/`, `vim` -> `$APPS/vim-local/bin/vim` (prefix install, prefix stays fixed), `xclip` -> `$APPS/xclip/build/bin/xclip` (git checkout).
- fzf is `~/.fzf/bin/fzf`, on PATH through fzf's own shell integration.

NCShare (`APPS=~/apps`, home is `/hpc/home/uherathmudiyanselage1`): not migrated yet, and not verified on the machine. Its `.bashrc` has PATH entries for `~/apps/ripgrep-14.1.1-x86_64-unknown-linux-musl/`, `~/apps/bat` and `~/apps/yazi/target/release/`, and vim was at `~/apps/vim`. Run the discovery step, then the migration below, then update this section.

## Migrating a cluster

Do this when tools resolve through `.bashrc` PATH entries instead of `$BIN`. Show the user the plan first, since it renames dirs and removes old trees.
1. Update the tools first, so each one moves only once.
2. For each multi-file tool, rename or create `$APPS/<tool>-X.Y.Z/` with the current version, then `ln -sfn` the binary into `$BIN`. A dir that's a cargo build tree (e.g., `yazi/target/release`) gets replaced by a fresh dir holding just the release binaries. Delete the old tree only after the new binaries are in place and run, and only with the user's OK. Check `git status` first if it's a checkout.
3. Keep vim's install prefix as is (configure baked it into the binary) and keep xclip's checkout. Only link them.
4. Back up `~/dotfiles/locations/<cluster>/.bashrc` to the scratch dir, then remove the PATH lines for the migrated tools only. Leave other lines in those blocks (e.g., the miniforge `LD_LIBRARY_PATH` line that sat under `# vim` on DCC). Show the diff.
5. Verify in a clean login shell that every tool resolves to `$BIN` and nothing else on PATH shadows it (`type -a -P TOOL`), and run each version command.

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

vim: the latest tag is `git ls-remote --tags --refs https://github.com/vim/vim.git | sed 's#.*refs/tags/##' | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -1`. The installed version is line 1's version plus the max of "Included patches" (e.g., 9.2.0424). Use the existing install's prefix (the parent of the real `bin/`, so resolve the `$BIN/vim` symlink first). Shallow-clone the tag and build in `src/`:
- If configure finds no terminal library (DCC has no `libtinfo.so` dev symlink), use `--with-tlib=ncurses` with `CPPFLAGS=-I$HOME/.local/include LDFLAGS=-L$HOME/.local/lib`.
- Python 3 comes from conda/miniforge. Its sysconfig names the static `libpython3.X.a`, so configure disables Python or bakes in a bad dlopen name. Pass `vi_cv_dll_name_python3=<LIBDIR>/libpython3.X.so` in the environment, `--with-python3-command=$(command -v python3)`, and add `-L<LIBDIR>` to LDFLAGS. Get LIBDIR from `python3 -c 'import sysconfig; print(sysconfig.get_config_var("LIBDIR"))'`. Verified on DCC 2026-11-21 (9.2.1382, Python 3.13). Test before installing with `env -i HOME=$HOME PATH=/usr/bin ./vim -es -u NONE -c 'redir! >out' -c 'py3 import sys; print(sys.version)' -c 'redir END' -c q`, since `-es` swallows `print` output.
- Full flags: `--prefix=<prefix> --with-features=huge --enable-python3interp=dynamic --with-x --enable-gui=no --enable-terminal`.
- Before installing, check that `./vim --version` keeps every `+feature` the current build has (at least `+clipboard +python3/dyn +terminal`, and `+X11` if present now). If any is missing, stop and report. Otherwise `rm -f <prefix>/bin/vim && make install`.
- Run `vim -es -u NONE -c 'py3 print(1)' -c q` to confirm Python loads.
- Remind the user that plugins update separately with `:PlugUpdate`.

If a source build fails, leave the existing install alone and report the error.
