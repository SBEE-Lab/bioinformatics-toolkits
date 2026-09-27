let
  flake = builtins.getFlake (toString ./..);
  packages = flake.packages.x86_64-linux;
  packageNames = builtins.attrNames packages;

  formatLicense =
    license:
    if builtins.isAttrs license && license ? spdxId then
      license.spdxId
    else if builtins.isAttrs license && license ? shortName then
      license.shortName
    else if builtins.isAttrs license && license ? fullName then
      license.fullName
    else if builtins.isString license then
      license
    else
      "Check package";

  extractMetadata =
    pkg:
    let
      license = pkg.meta.license or null;
    in
    {
      description = pkg.meta.description or "No description available";
      license =
        if license == null then
          "Check package"
        else if builtins.isList license then
          builtins.concatStringsSep " / " (builtins.map formatLicense license)
        else
          formatLicense license;
      homepage = pkg.meta.homepage or null;
      mainProgram = pkg.meta.mainProgram or null;
      category = pkg.passthru.category or "Uncategorized";
      hideFromDocs = pkg.passthru.hideFromDocs or false;
    };
in
builtins.listToAttrs (
  builtins.map (name: {
    inherit name;
    value =
      let
        pkg = packages.${name} or null;
        metadata = if pkg == null then null else extractMetadata pkg;
      in
      if metadata != null && !metadata.hideFromDocs then metadata else null;
  }) packageNames
)
