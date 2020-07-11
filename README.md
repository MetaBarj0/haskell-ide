# Integrated Development Environment for Haskell

A ready to use development environment working with docker and virtualbox
through vagrant and Metabarj0's DockerBox (specified as a git submodule).
It contains the ghc-8.8.3 and neovim.

## Usage

1. Clone it : `git clone --recurse-submodules https://github.com/MetaBarj0/haskell-ide.git`
2. Copy `.env/dist.haskell-ide` to `machine/.env`
3. Modify the environment values to better suit your need and machine
capacity in `machine/.env` file
    1. `MACHINE_CPU` can be greater than the default value, depending on your
    machine capacity
    2. `MACHINE_MEM` can be greater than the default value, depending on your
    machine capacity
    3. `MACHINE_SYNC_FOLDER` must be setup especially for ssh directory. It
    will be used to securely copy both your public and secret keys using
    `docker secrets`. It is important if you plan to use your keys within the
    container.
    4. `KV_DB_ITEMS` must be set accordingly to the synced folder that
    contains your ssh keys. It must contains at least one item with a key
    `ssh_dir` and a value corresponding to the path where keys can be found.
    Moreover, a value `reset_stack_on_provision` can be set to `true` if you
    want to reset the docker stack each time you provision your machine. It
    is useful if you need to reconfigure the stack or update secrets. Note
    however that any state that is not persisted (volume, ...) is discarded
    at stack reset.
4. Create and boot the virtual machine with `vagrant up` in the `machine` directory
5. Halt the machine with `vagrant halt`. Yeah that's weird but wait...
6. Add a disk to the newly created virtual machine using the virtual box
   hypervisor capabilities (gui, command line tool, whatever you prefer). Make
   sure you add at least a 6GB sized disk. It's necessary because building the
   system is greedy. However, once finished, a lot of space is swiped.
7. Reboot and provision the machine with `vagrant up --provision`
8. Enter you IDE with : `vagrant ssh`
9. Within your dev container, several files will be created using template
   files passed as configuration. Those files have the `.dist` extension and are
   read-only. Feel free to modify generated files with values that suit your
   need (i.e. /home/hsdev/.config/nvim/plugins.vim)

Note that the very first time you will `vagrant ssh`, you'll have to like
coffe or tea, because a lot of things will be built. It occurs only once
though unless you destroy your machine.

Happy Hackskelling ;)
