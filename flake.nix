{
  description = "bioinformatics-toolkits — Nix package registry for bioinformatics";

  nixConfig = {
    allow-import-from-derivation = false;
    extra-substituters = [ "https://cache.sjanglab.org" ];
    extra-trusted-public-keys = [ "cache.sjanglab.org-1:VzE09zCt/P+zsSqRq7nyIPVoQXdADRyRsoF1x25ul1U=" ];
  };

  inputs = {
    # keep-sorted start
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    # keep-sorted end
  };

  outputs =
    inputs@{ self, nixpkgs, ... }:
    let
      inherit (nixpkgs) lib;

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      eachSystem = lib.genAttrs systems;

      callWith = args: fn: fn (builtins.intersectAttrs (builtins.functionArgs fn) args);

      flake = self // {
        inherit inputs;
      };

      packageNames = builtins.attrNames (
        lib.filterAttrs (
          name: type: type == "directory" && builtins.pathExists (./packages + "/${name}/package.nix")
        ) (builtins.readDir ./packages)
      );

      pkgsFor = eachSystem (
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        }
      );

      mkPackagesFor =
        pkgs:
        let
          system = pkgs.stdenv.hostPlatform.system;
          scope = lib.makeScope pkgs.newScope (
            scopeSelf:
            {
              inherit flake inputs system;
              allPackages = packages;
            }
            // lib.genAttrs packageNames (name: scopeSelf.callPackage (./packages + "/${name}/package.nix") { })
          );
          packages = lib.genAttrs packageNames (name: scope.${name});
        in
        packages;

      allPackages = eachSystem (system: mkPackagesFor pkgsFor.${system});

      available =
        system: pkg:
        lib.meta.availableOn pkgsFor.${system}.stdenv.hostPlatform pkg && !(pkg.meta.broken or false);

      packages = eachSystem (system: lib.filterAttrs (_name: available system) allPackages.${system});

      devShells = eachSystem (system: {
        default = callWith {
          pkgs = pkgsFor.${system};
          perSystem.self = allPackages.${system};
          inherit inputs system;
        } (import ./devshell.nix);
      });
    in
    {
      inherit packages devShells;

      overlays.shared-nixpkgs = import ./overlays/shared-nixpkgs.nix { inherit mkPackagesFor; };

      checks = eachSystem (
        system:
        lib.mapAttrs' (name: pkg: lib.nameValuePair "pkgs-${name}" pkg) (
          lib.filterAttrs (_name: pkg: !(pkg.requireFile or false)) packages.${system}
        )
        // {
          devshell-default = devShells.${system}.default;
        }
      );

      formatter = eachSystem (system: allPackages.${system}.formatter);
    };
}
