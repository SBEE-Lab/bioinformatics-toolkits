{ pkgs, perSystem }:
pkgs.mkShell {
  packages = with pkgs; [
    gh
    git
    nix
    nix-update
    python3
    perSystem.self.formatter
  ];
}
