{
  description = "A very basic flake";

  inputs.globalRegistry.url = "github:NixOS/flake-registry";
  inputs.globalRegistry.flake = false;

  outputs = { globalRegistry, ... }: {
    nixosModules.local-registry = { config, lib, pkgs, ... }:
      let cfg = config.nix.localRegistry;
      in {
        options = {
          nix.localRegistry.enable = lib.mkEnableOption ''
            Download a local copy of nixpkgs to /nix/nixpkgs and set it as the default registry entry for "nixpkgs".
          '';
          nix.localRegistry.cacheGlobalRegistry = lib.mkEnableOption ''
            Cache the default nix registry locally, to avoid extraneous registry updates from nix cli.
          '';
          nix.localRegistry.noGlobalRegistry = lib.mkEnableOption ''
            Set an empty global registry.
          '';
        };

        config = lib.mkIf cfg.enable {

          nix.extraOptions = let
            registry = if cfg.noGlobalRegistry then
              builtins.toFile "registry.json" (builtins.toJSON { version = 2; })
            else
              "${globalRegistry}/flake-registry.json";
          in lib.mkIf (cfg.cacheGlobalRegistry || cfg.noGlobalRegistry)
          "flake-registry = ${registry}";

          nix.registry.nixpkgs = {
            exact = false;
            from.id = "nixpkgs";
            from.type = "indirect";
            to.url = "file:///nix/nixpkgs";
            to.type = lib.mkForce "git";
          };

          systemd.timers.sync-nixpkgs = {
            description =
              "Keep a local copy of nixpkgs up to date with the GitHub remote";

            after = [ "network.target" ];
            wantedBy = [ "multi-user.target" ];

            timerConfig = {
              Peristent = true;
              OnCalendar = "*-*-* 00:00:00";
              Unit = "sync-nixpkgs.service";
            };
          };

          systemd.services.sync-nixpkgs = {
            description = "Sync a local nixpkgs with the GutHub remote";
            after = [ "network.target" ];
            path = with pkgs; [ git hub coreutils gawk ];
            serviceConfig = {
              ExecStartPre = pkgs.writeShellScript "sync-pre" ''
                if ! git ls-remote /nix/nixpkgs -0 &> /dev/null; then
                  git clone --quiet https://github.com/NixOS/nixpkgs.git /etc/nixpkgs
                fi

                cd /nix/nixpkgs
                git remote update --prune

                # ensure all remote branches exist locally and track upstream
                for branch in $(git branch -r | tail -n +2); do
                  git branch ${"\${branch#*/}"} $branch -f
                done

                # delete any branch without an upstream equivalent
                git branch -D $(git for-each-ref --format="%(if)%(upstream)%(then)%(else)%(refname:short)%(end)" refs/heads) || true

                # delete any unmerged branches that no longer exist on remote (backports, reversions)
                git branch -D $(git branch -vv | awk '/: gone]/{print $1}') || true
              '';
              ExecStart = pkgs.writeShellScript "sync-nixpkgs" ''
                cd /nix/nixpkgs

                # update heads of local branches
                hub sync
              '';
            };
          };
        };

      };
  };
}
