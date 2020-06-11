# Integrated Development Environment for Haskell

A ready to use development environment working with docker and virtualbox
through vagrant and Metabarj0's DockerBox.

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
4. Create and boot the virtual machine with `vagrant up`
5. Halt the machine with `vagrant halt`. Yeah that's weird but wait...
6. Add a disk to the newly created virtual machine using the virtual box
hypervisor capabilities (gui, command line tool, whatever you prefer). Make
sure you add at least a 6GB sized disk.
7. Reboot and provision the machine with `vagrant up --provision`
8. Enter you IDE with : `vagrant ssh`

Note that the very first time you will `vagrant ssh`, you'll have to like
coffe or tea, because a lot of things will be built. It occurs only once
though unless you destroy your machine.

Happy Hackskelling ;)
