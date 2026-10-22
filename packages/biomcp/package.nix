{
  lib,
  rustPlatform,
  fetchFromGitHub,
  stdenv,
  makeWrapper,
  installAgentSkills,
  cacert,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "biomcp";
  version = "0.9.3";

  __structuredAttrs = true;
  strictDeps = true;

  src = fetchFromGitHub {
    owner = "genomoncology";
    repo = "biomcp";
    tag = "v${finalAttrs.version}";
    hash = "sha256-qYwdnXMxQWDc2AWzAv/AD6CcOR84IPUM+6xdosQKQwU=";
  };

  cargoHash = "sha256-ZC0gPYNnSUURnzvPPKuJ7R217BPbCTN8nrQID07TGY0=";

  # v0.9.2 and upstream main still let host disk pressure evict stale-test
  # fixtures. Isolate their disk-free floor without changing runtime defaults.
  patches = [ ./isolate-stale-cache-fixtures.patch ];

  nativeBuildInputs = [
    installAgentSkills
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [ makeWrapper ];

  # Upstream only supports nextest; under one libtest process its
  # env-mutating serial tests hang behind each other's locks.
  useNextest = true;
  # Test-only env hooks are compiled under debug_assertions.
  checkType = "debug";
  cargoTestFlags = [ "--lib" ];

  dontInstallAgentSkills = true;

  postInstall = ''
    installSkill ${finalAttrs.src}/skills
  '';

  preCheck = ''
    export HOME="$TMPDIR/home"
    export XDG_CACHE_HOME="$TMPDIR/cache"
    export XDG_CONFIG_HOME="$TMPDIR/config"
    export XDG_DATA_HOME="$TMPDIR/data"
    mkdir -p "$HOME" "$XDG_CACHE_HOME" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME"
  '';

  postFixup = lib.optionalString stdenv.hostPlatform.isLinux ''
    for bin in biomcp biomcp-cli; do
      wrapProgram "$out/bin/$bin" \
        --set-default SSL_CERT_FILE "${cacert}/etc/ssl/certs/ca-bundle.crt"
    done
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    export HOME="$TMPDIR/home"
    export XDG_CACHE_HOME="$TMPDIR/cache"
    export XDG_CONFIG_HOME="$TMPDIR/config"
    export XDG_DATA_HOME="$TMPDIR/data"
    mkdir -p "$HOME" "$XDG_CACHE_HOME" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME"

    $out/bin/biomcp --version
    $out/bin/biomcp-cli --version
    $out/bin/biomcp list >/dev/null
    $out/bin/biomcp serve-http --help >/dev/null

    test -f "$out/share/skills/biomcp/skills/SKILL.md"
    diff -r ${finalAttrs.src}/skills "$out/share/skills/biomcp/skills"

    runHook postInstallCheck
  '';

  passthru.category = "Data";

  meta = {
    description = "Biomedical CLI and MCP server for biomedical data sources";
    homepage = "https://biomcp.org";
    changelog = "https://github.com/genomoncology/biomcp/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    mainProgram = "biomcp";
    platforms = lib.platforms.unix;
  };
})
