# dotfiles

This is a repository to keep my dotfiles and other system related scripts which are synced between different computing systems.
Settings for each local computer and remote cluster can be found in the /locations directory.

Local machines:
- mac (Uthpalas-Macbook-Pro)
- desktop
- desktop2

Remote clusters:
- whitehall (WVU Physics and Astronomy)
- spruce (Spruce Knob WVU High Performance Computing)
- thorny (Thorny Flat WVU High Performance Computing)
- bridges (Bridges - Pittsburgh Supercomputing Center)
- stampede2 (Stampede2 - Texas Advanced Computing Center)

I basically create symlinks of each of the files in the directories to the system root.

TODO: Create a bootstrap script to automate the setup and linking.

## Forks

Here's a list of repositories that I have forked and modified. 

- [.tmux](https://github.com/uthpalaherath/.tmux):
    Originally created by [gpakosz](https://github.com/gpakosz/.tmux) to modify tmux configuration. **.tmux.conf.local** contains my configuration. 

- [vimrc](https://github.com/uthpalaherath/vimrc):
    Originally created by [amix](https://github.com/amix/vimrc) to modify vim configuration. **my_configs.vim** contains my configuration. 

- [pandoc-templates](https://github.com/uthpalaherath/pandoc-templates):
    Originally created by [jgm](https://github.com/jgm/pandoc-templates) as a conversion tool for markdown files. My scripts are in the **/scripts** directory. For markdown -> latex conversions I use a costomized **default.latex** file.   


Disclaimer: *I am a computational physicist, not a computer scientist. These scripts may not look very professional or adhere to coding conventions. They may also contain bugs.*

Most of these scripts were written based on ideas of smart people on forums and repositories around the internet. Unfortunately, I have not been able to keep track of every single one of them to give credit to the original creators so if you find something I forgot to acknowledge please let me know.
