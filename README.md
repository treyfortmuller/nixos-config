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

---

Notes on `spotifyd` and `spt`

- trying to authenticate with the 1password CLI `op`
- eval $(op signin) - what does this do to my environment?

To get this working manually outside of systemd, all in the same terminal

```
eval $(op signin)

# to keep this thing from detaching, `--no-daemon`
spotify --no-deamon --config-path /nix/store/...

# where I stole the nix store path for the config file from
systemctl status --user spotifyd which is provided by my nixos config
```

Then in a new terminal we can open the spotify TUI

```
spt
# proceed to jam out
```

### Other Resources

* [nix-starter-configs](https://github.com/Misterio77/nix-starter-configs/tree/main) from Gabriel Fontes, well-documented and modern flake setup.
* [jringer's config](https://github.com/jonringer/nixpkgs-config/tree/master) because Jon knows what he is talking about.