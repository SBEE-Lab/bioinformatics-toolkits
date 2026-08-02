{
  flake,
  inputs,
  pkgs,
}:
let
  formatter = inputs.treefmt-nix.lib.mkWrapper pkgs {
    _file = __curPos.file;
    imports = [ ./treefmt.nix ];
  };

  check =
    pkgs.runCommand "format-check"
      {
        nativeBuildInputs = [
          formatter
          pkgs.git
        ];
      }
      ''
        export HOME=$NIX_BUILD_TOP/home
        cp --preserve=mode,timestamps -r ${flake} source
        chmod -R u+w source
        cd source
        git init --quiet
        git add .
        treefmt --no-cache
        git diff --exit-code
        touch $out
      '';
in
formatter
// {
  passthru = formatter.passthru // {
    hideFromDocs = true;
    skipUpdate = true;
    tests.check = check;
  };
}
