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

A minimal ISO installer image for a `sierras` base configuration (basically my entire desktop config modulo any hardware-specific configurations) can be generated with

```
nix build -j8 .#nixosConfigurations.base.config.system.build.images.iso-installer
```

This build took 30 minutes on my 8 core ThinkPad with a nix store which was already a hot cache. That'll spit out a `result` symlinked to an `.iso` we can use `caligula` to burn onto a removable media

```
nix-shell -p caligula

caligula burn ./nixos-...-linux.iso
```

Boot that media and you're basically following the [NixOS manual install](https://nixos.org/manual/nixos/stable/#sec-installation-manual) instructions for the minimal (i.e. GUI-less) installer.

### Other Resources

* [nix-starter-configs](https://github.com/Misterio77/nix-starter-configs/tree/main) from Gabriel Fontes, well-documented and modern flake setup.
* [jringer's config](https://github.com/jonringer/nixpkgs-config/tree/master) because Jon knows what he is talking about.

### TODO

* more fzf customization, bat previews, vim-plugins, etc.
* Some basic CI for the repo with `nix flake check .#`
