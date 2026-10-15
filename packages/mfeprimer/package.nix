{
  lib,
  stdenv,
  fetchurl,
  gzip,
}:

let
  sources = {
    x86_64-linux = {
      asset = "linux-amd64";
      hash = "sha256-vDVGhAYTpXPSm3KgM9l/RBDeWrBeXsaObWVM0xj7+HA=";
    };
    aarch64-linux = {
      asset = "linux-arm64";
      hash = "sha256-Md/rLzy5pYryjf8aAtgCT3dAI28hQNOzT6J3F2nXY3I=";
    };
    x86_64-darwin = {
      asset = "darwin-amd64";
      hash = "sha256-ba0lcViIQqvan7X3/p1TwJUsOJtmMoI02J3F8A5SdLA=";
    };
    aarch64-darwin = {
      asset = "darwin-arm64";
      hash = "sha256-/Fzy5QqpKhQCyUsNy+N/ljEuWQRJFgHXJapvLZR8QUk=";
    };
  };
  source = sources.${stdenv.hostPlatform.system};
in
stdenv.mkDerivation (finalAttrs: {
  pname = "mfeprimer";
  version = "4.5.2";

  src = fetchurl {
    url = "https://github.com/quwubin/MFEprimer-3.0/releases/download/v${finalAttrs.version}/mfeprimer-${finalAttrs.version}-${source.asset}.gz";
    inherit (source) hash;
  };

  nativeBuildInputs = [ gzip ];

  dontUnpack = true;
  dontPatchELF = true;
  dontStrip = true;
  strictDeps = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin"
    gzip -dc "$src" > "$out/bin/mfeprimer"
    chmod 0555 "$out/bin/mfeprimer"
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    test "$("$out/bin/mfeprimer" version)" = "mfeprimer ${finalAttrs.version}"
    runHook postInstallCheck
  '';

  passthru.category = "Sequence";

  meta = {
    description = "Check PCR primer specificity, dimers, hairpins, and other properties";
    homepage = "https://www.mfeprimer.com/";
    # Upstream permits free commercial and non-commercial use, but publishes no
    # license granting redistribution of the closed-source release binaries.
    license = lib.licenses.unfree;
    platforms = builtins.attrNames sources;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "mfeprimer";
  };
})
