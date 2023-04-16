# nixos-config

TODO
- [ ] `home-manager`'s `services.screen-locker` seems useful for autolocking
- [ ] vscode config tracked in home-manager
- [x] i3 config tracked in home-manager
- [ ] setup some nix eval CI for this repo
- [ ] rofi power menu setup
- [ ] polybar/i3bar configuration
- [ ] i3 managed with home-manager
- [ ] provide an overlay or some other way of synthesizing work and home from a base config

Explore the current configuration with the repl, you'll be abel to access the `config` attrset after this path is loaded

```
nix repl>:l <nixpkgs/nixos>
```

And similarly, against the configuration of your current system via `nix-instantiate`:

```bash
nix-instantiate --eval -E '(import <nixpkgs/nixos> {}).config.nixpkgs.config.allowUnfree'
```

---

Notes on spotifyd and spt

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

