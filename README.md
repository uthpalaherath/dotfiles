# dotfiles

This is a repository to keep my dotfiles and other system related scripts which are synced between different computing systems.
Settings for each local computer and remote cluster can be found in the /locations directory.

Local machines:
- mac

Remote clusters:
- whitehall (WVU Physics and Astronomy)
- spruce (Spruce Knob WVU High Performance Computing)
- thorny (Thorny Flat WVU High Performance Computing)
- bridges (Bridges - Pittsburgh Supercomputing Center)
- bridges2 (Bridges2 - Pittsburgh Supercomputing Center)
- stampede2 (Stampede2 - Texas Advanced Computing Center)
- frontera (Frontera - Texas Advanced Computing Center)
- perlmutter (NERSC cluster)
- timewarp (Duke AIMS Lab cluster)
- dcc (Duke DCC cluster)
- ncshare (NCShare cluster)

I basically create symlinks of each of the files in the directories to the system root.

## tmux

`configs/tmux.conf` is a standalone config (needs tmux 3.6+ and a Nerd Font). Symlink it to `~/.config/tmux/tmux.conf`, clone [tpm](https://github.com/tmux-plugins/tpm) into `~/.config/tmux/plugins/tpm`, then press `prefix I` to install plugins.

## vim

`vim/vimrc` is a standalone config managed by [vim-plug](https://github.com/junegunn/vim-plug). Symlink it to `~/.vimrc` and `vim/coc-settings.json` to `~/.vim/coc-settings.json`, then start vim; plugins install on first launch. Update them with `:PlugUpdate`.

Disclaimer: *I am a computational physicist, not a computer scientist. These scripts may not look very professional or adhere to coding conventions. They may also contain bugs.*

Most of these scripts were written based on ideas of smart people on forums and repositories around the internet. Unfortunately, I have not been able to keep track of every single one of them to give credit to the original creators so if you find something I forgot to acknowledge please let me know.
