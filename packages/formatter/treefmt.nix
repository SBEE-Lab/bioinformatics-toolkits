{ pkgs, ... }:
{
  projectRootFile = "flake.nix";

  programs = {
    deadnix.enable = true;
    keep-sorted.enable = true;
    nixfmt.enable = true;
    prettier = {
      enable = true;
      includes = [
        "*.md"
        "*.markdown"
      ];
    };
    ruff-format.enable = true;
    statix.enable = true;
  };

  settings.formatter.nu-check = {
    command = "${pkgs.nushell}/bin/nu";
    options = [ (toString ../../scripts/treefmt-nu-check.nu) ];
    includes = [ "*.nu" ];
  };
}
