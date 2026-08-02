{
  lib,
  stdenv,
  fetchFromGitHub,
  makeWrapper,
  tcsh,
  coreutils,
  # Only runpsipred needs the legacy BLAST tools absent from nixpkgs.
  blast ? null,
}:
stdenv.mkDerivation (_finalAttrs: {
  pname = "psipred";
  # Repo has no release tags; track master HEAD by commit date (README: V4).
  version = "4.0";

  src = fetchFromGitHub {
    owner = "psipred";
    repo = "psipred";
    rev = "4e8d136076bc0af1534cac053cb54d1ee641571a";
    hash = "sha256-nQDTqmf0OgcoYceDhR/EKqnaQeUaZ22EszzOPOUfTyM=";
  };

  nativeBuildInputs = [ makeWrapper ];

  buildPhase = ''
    runHook preBuild
    # Replace upstream's FHS-linked binaries with Nix-built ones.
    rm -f src/psipred src/psipass2 src/chkparse src/seq2mtx
    # GCC 14 requires the legacy sources to use the gnu89 dialect.
    make -C src all CC=$CC CFLAGS="-O -std=gnu89"
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin $out/libexec/psipred $out/share/psipred/data

    install -Dm755 src/psipred src/psipass2 src/chkparse src/seq2mtx -t $out/bin
    cp -r data/. $out/share/psipred/data/

    # Replace FHS and relative paths in the driver scripts.
    for s in runpsipred runpsipred_single; do
      cp $s $out/libexec/psipred/$s
      substituteInPlace $out/libexec/psipred/$s \
        --replace-fail '#!/bin/tcsh' '#!${tcsh}/bin/tcsh' \
        --replace-fail 'set execdir = ./bin' "set execdir = $out/bin" \
        --replace-fail 'set datadir = ./data' "set datadir = $out/share/psipred/data"
      makeWrapper $out/libexec/psipred/$s $out/bin/$s \
        --prefix PATH : ${lib.makeBinPath ([ coreutils ] ++ lib.optional (blast != null) blast)}
    done
    runHook postInstall
  '';

  # Test the database-free path on the bundled example.
  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    cp example/example.fasta query.fasta
    $out/bin/runpsipred_single query.fasta
    test -s query.ss2 || { echo "psipred produced no .ss2 prediction"; exit 1; }
    echo "install check OK: $(wc -l < query.ss2) lines in query.ss2"
    runHook postInstallCheck
  '';

  passthru.category = "Sequence Analysis & Design";

  meta = {
    description = "PSIPRED V4 protein secondary structure prediction";
    homepage = "https://github.com/psipred/psipred";
    # Custom UCL license with redistribution restrictions.
    license = lib.licenses.unfree;
    platforms = lib.platforms.unix;
  };
})
