# testnix

Flake-based NixOS test project.

## Usage

```bash
nix flake show
nixos-rebuild switch --flake .#test
```

Replace the placeholder UUIDs in `hardware-configuration.nix` with values from `nixos-generate-config` or your existing host.
