{
  lib,
  stdenv,
  buildBazelPackage,
  fetchFromGitHub,
  fetchzip,
  bazel_7,
  jdk21,
}:

let
  registry = fetchFromGitHub {
    owner = "bazelbuild";
    repo = "bazel-central-registry";
    rev = "dc643526b97838ffe421b833dd8b9c95e71702e8";
    hash = "sha256-SLtrNU5uEt8rRJDUdV/IaI37CujsTHLlE31l2zYoRss=";
  };
  depsHashes = builtins.fromJSON (builtins.readFile ./deps.json);
  commonMeta = {
    description = "NCBI command-line tool to gather data from NCBI databases";
    homepage = "https://github.com/ncbi/datasets";
    license = lib.licenses.publicDomain;
    mainProgram = "datasets";
  };
  version = "18.37.0";
  commit = "c641ac110f9f4d756c67e678f646bb1b711b1dd3";

  # Bazel dependencies vary by platform. Use upstream Darwin binaries so
  # updates do not require a macOS runner solely to refresh their hash.
  darwinPackage = stdenv.mkDerivation {
    pname = "ncbi-datasets";
    inherit version;

    src = fetchzip {
      url = "https://github.com/ncbi/datasets/releases/download/v${version}/darwin-arm64.cli.package.zip";
      hash = "sha256-fTGU/CYEs9GrT7l3Ks6FiOTvLL/IsATq9vic30pY6G4=";
      stripRoot = false;
    };

    installPhase = ''
      runHook preInstall
      install -Dm555 -t "$out/bin" datasets dataformat
      runHook postInstall
    '';

    passthru.category = "Data";

    meta = commonMeta // {
      platforms = [ "aarch64-darwin" ];
    };
  };

  linuxPackage = buildBazelPackage {
    pname = "ncbi-datasets";
    inherit version;

    src = fetchFromGitHub {
      owner = "ncbi";
      repo = "datasets";
      rev = commit;
      hash = "sha256-/m00Kt4LIFH5nc4L8zsWdkBR1Yec5eC3//UpkxFXrTA=";
    };

    sourceRoot = "source/client";

    postPatch = ''
      printf '%s\n' \
        '#!${stdenv.shell}' \
        'cat <<STATUS' \
        'SOFTWARE_VERSION v${version}' \
        'STABLE_SOFTWARE_VERSION v${version}' \
        'STABLE_SOFTWARE_VERSION_WITHOUT_PREFIX ${version}' \
        'STABLE_GIT_COMMIT ${commit}' \
        'STABLE_GIT_COMMIT_SHORT ${builtins.substring 0 7 commit}' \
        'GIT_BRANCH v${version}' \
        'GIT_BRANCH_TAG v${version}' \
        'STATUS' \
        > workspace_status.sh
      chmod +x workspace_status.sh
      substituteInPlace .bazelrc \
        --replace-fail 'build --workspace_status_command=workspace_status.sh' "build --workspace_status_command=$PWD/workspace_status.sh"
      substituteInPlace apps/public/Datasets/v2/cmd/datasets/BUILD.bazel \
        --replace-fail '{STABLE_SOFTWARE_VERSION_WITHOUT_PREFIX}' '${version}'
    '';

    bazel = bazel_7;
    bazelFlags = [
      "--registry"
      "file://${registry}"
    ];

    nativeBuildInputs = [ jdk21 ];

    bazelBuildFlags = [
      "--java_runtime_version=local_jdk"
    ];

    bazelTargets = [
      "//apps/public/Datasets/v2/cmd/datasets:datasets"
    ];

    removeRulesCC = false;

    fetchAttrs = {
      preInstall = ''
        chmod -R +w "$bazelOut/external"
        rm -rf "$bazelOut/external/rules_shell~~sh_configure~local_config_shell"
        # Go build-cache entries contain per-run build IDs and are not needed
        # when Bazel consumes the fetched repositories in the build phase.
        rm -rf "$bazelOut/external/gazelle~~non_module_deps~bazel_gazelle_go_repository_cache/gocache"
      '';

      hash =
        depsHashes.${stdenv.hostPlatform.system}
          or (throw "No deps hash for system: ${stdenv.hostPlatform.system}");
    };

    buildAttrs = {
      installPhase = ''
        runHook preInstall
        install -Dm555 \
          bazel-bin/apps/public/Datasets/v2/cmd/datasets/datasets_/datasets \
          "$out/bin/datasets"
        runHook postInstall
      '';
    };

    passthru.category = "Data";

    meta = commonMeta // {
      platforms = [ "x86_64-linux" ];
    };
  };
in
if stdenv.hostPlatform.isDarwin then darwinPackage else linuxPackage
