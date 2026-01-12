# nixos-config

Drink this Kool-Aid, its delicious. These are the flake-based NixOS system configurations for all my machines. Downstream consumers at work, etc. can depend on this repo as a flake input by grabbing `nixosModules.base`. Here's some common nix CLI invocations for revving the config.

Check that eval is gucci:

```
nix flake check
```

Test a build:

```
nixos-rebuild build --flake .#kearsarge
```

Rebuild switch/boot:

```
nixos-rebuild boot --flake .#kearsarge
sudo reboot now
```

Explore the current configuration through the repl:

```
[nix-shell:~/sources/nixos-config]$ nix repl
Welcome to Nix 2.13.6. Type :? for help.

# Load the flake at the current directory
nix-repl> :lf .

# Go nuts...
nix-repl> nixosConfigurations.kearsarge.config
```

Build a system closure directly:

```
nix build .#nixosConfigurations.kearsarge.config.system.build.toplevel
```

Update a flake input:

```
nix flake update nixpkgs
```

Override a flake input with a local checkout:

```
nix flake lock --override-input nixpkgs ../nixpkgs
```

### New Machine Bringup

TODO

### nixbuild.net

nixbuild.net is remote builders for hire. They'll give you 25 free CPU-hours after you sign up which is pretty sweet. I use them for big aarch64 builds, where cross compilation isn't either possible or isn't worth figuring out. There's a `nixbuild-net.nix` module in this tree to set up the config. The TLDR is that you'll need to register your SSH public key with nixbuild.net, and then call out the path to your private key via the options I exposed in that module.

See the getting started docs [here](https://docs.nixbuild.net/getting-started/).

You can verify shell access with

```
sudo ssh eu.nixbuild.net shell
```

and try out your first (aarch64) build with 

```
nix-build \
  --max-jobs 0 \
  --builders "ssh://eu.nixbuild.net aarch64-linux - 100 1 big-parallel,benchmark" \
  --system aarch64-linux \
  -I nixpkgs=channel:nixos-20.03 \
  --expr '((import <nixpkgs> {}).runCommand "test${toString builtins.currentTime}" {} "echo Hello nixbuild.net; touch $out")'
```

This should print "Hello nixbuild.net" (among other things) and drop an `result` symlink to an empty nix store path in your current directory. You're off to the races.

### Other Resources

* [nix-starter-configs](https://github.com/Misterio77/nix-starter-configs/tree/main) from Gabriel Fontes, well-documented and modern flake setup.
* [jringer's config](https://github.com/jonringer/nixpkgs-config/tree/master) because Jon knows what he is talking about.

### TODO

* Some basic CI for the repo with `nix flake check .#`
