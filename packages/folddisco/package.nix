{
  lib,
  rustPlatform,
  fetchFromGitHub,
  cmake,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "folddisco";
  version = "3-3e193e3";

  src = fetchFromGitHub {
    owner = "steineggerlab";
    repo = "folddisco";
    tag = finalAttrs.version;
    hash = "sha256-JllZlx7bdbLSZBmVyvzGi/6xbYdz/tyyGXUf6s6Ll/4=";
  };

  cargoHash = "sha256-gHxXU64T465ejxRcX78bnKpmD0KRrLnqNiN8jVq3AH4=";

  # The default "foldcomp" feature compiles the vendored lib/foldcomp C++ FFI
  # via the cmake crate (cmake) and generates bindings (bindgenHook → libclang).
  nativeBuildInputs = [
    cmake
    rustPlatform.bindgenHook
  ];

  # build.rs drives cmake itself; the cmake setup hook must not hijack configure.
  dontUseCmakeConfigure = true;

  # build.rs derives the version from .git, absent in the sandbox; supply it so
  # `folddisco --version` reports the release instead of "unknown".
  env.FOLDDISCO_BUILD_VERSION = finalAttrs.version;

  passthru.category = "Structure";

  meta = {
    description = "Finding discontinuous motifs in protein structures";
    homepage = "https://github.com/steineggerlab/folddisco";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.unix;
    mainProgram = "folddisco";
  };
})
