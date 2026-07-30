{ pkgs }:
{
  biotite = pkgs.callPackage ./biotite { };
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
