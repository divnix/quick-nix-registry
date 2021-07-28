# quick-nix-registry

> this module is only useful for users of nix flakes and NixOS

POC of [NixOS/nix#4602](https://github.com/NixOS/nix/issues/4602), which I hope will add a native notion of a local mirror to Nix.
In the meantime, this module will speed up all your references to the `"nixpkgs"` flake, by mirroring a copy of on your local machine at `/nix/nixpkgs`.

### ⚠ Warning!
This will set the registry to `/nix/nixpkgs` _before_ the systemd-timer has  a chance to run the initial sync.
If you want to trigger the sync manually, simply run `systemctl start sync-nixpkgs.service`.
In order to fully resolve this, Nix will have to become aware of [flake mirrors](https://github.com/NixOS/nix/issues/4602#issuecomment-887007534) to allow for a graceful fallback to GitHub.

## Usage

import the flake and then import the module:
```nix
# flake.nix
{
  inputs.qnr.url = "github:divnix/quick-nix-registry";

  outputs = { qnr, nixpkgs, ... }: {
    nixosConfigurations.mySystem = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        qnr.nixosModules.local-registry
        {
          # Enable quick-nix-registry
          nix.localRegistry.enable = true;

          # Cache the default nix registry locally, to avoid extraneous registry updates from nix cli.
          nix.localRegistry.cacheGlobalRegistry = true;

          # Set an empty global registry.
          nix.localRegistry.noGlobalRegistry = false;
        }
      ];
    };
  };
}
```
