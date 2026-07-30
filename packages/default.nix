{ pkgs }:
# rec: consurf bundles our own rate4site (not in nixpkgs) on its PATH.
rec {
  biotite = pkgs.callPackage ./biotite { };
  consurf = pkgs.callPackage ./consurf { inherit rate4site; };
  fair-esm = pkgs.callPackage ./fair-esm { };
  folddisco = pkgs.callPackage ./folddisco { };
  foldmason = pkgs.callPackage ./foldmason { };
  foldseek = pkgs.callPackage ./foldseek { };
  nupack = pkgs.callPackage ./nupack { };
  plmc = pkgs.callPackage ./plmc { };
  psipred = pkgs.callPackage ./psipred { };
  rate4site = pkgs.callPackage ./rate4site { };
  thermompnn = pkgs.callPackage ./thermompnn { };
  updater = pkgs.callPackage ./updater { };
  usalign = pkgs.callPackage ./usalign { };
}
// pkgs.lib.optionalAttrs (pkgs.stdenv.hostPlatform.system == "x86_64-linux") {
  cns = pkgs.callPackage ./cns { };
  maxcluster = pkgs.callPackage ./maxcluster { };
}
