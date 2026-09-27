{ pkgs, perSystem }:
pkgs.mkShell {
  packages =
    (with pkgs; [
      cargo
      gh
      git
      nix
      nix-update
      nushell
      python3
      perSystem.self.formatter
    ])
    ++ pkgs.lib.optional pkgs.stdenv.hostPlatform.isLinux pkgs.bubblewrap;
}
