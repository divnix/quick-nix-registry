# quick-nix-registry

> this module is only useful for users of nix flakes

POC of [NixOS/nix#4602](https://github.com/NixOS/nix/issues/4602), which I hope will add a native notion of a local mirror to Nix.
In the meantime, this module will speed up all your references to the `"nixpkgs"` flake, by mirroring a copy of on your local machine at `/nix/nixpkgs`.
