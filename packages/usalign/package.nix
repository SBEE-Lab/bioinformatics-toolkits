{
  lib,
  stdenv,
  fetchFromGitHub,
}:
stdenv.mkDerivation {
  pname = "usalign";
  version = "20260908";

  src = fetchFromGitHub {
    owner = "pylelab";
    repo = "USalign";
    rev = "6e4dc672a49cc925356039c4273f48d7ce216ef7";
    hash = "sha256-H+YKlo3J7n8O82Km0M62O0XpBAoZJymVUOeiD5GuK6Y=";
  };

  # Makefile hardcodes CC=g++; route it through the stdenv C++ wrapper so the
  # build works on both the gcc (Linux) and clang (Darwin) toolchains.
  makeFlags = [ "CC=c++" ];

  enableParallelBuilding = true;

  # Upstream ships no install target; the Makefile drops every binary in cwd.
  installPhase = ''
    runHook preInstall
    install -Dm755 -t $out/bin \
      qTMclust USalign TMalign TMscore MMalign se pdb2xyz xyz_sfetch \
      pdb2fasta biounitasym pdb2ss NWalign HwRMSD cif2pdb pdbAtomName addChainID
    runHook postInstall
  '';

  passthru.category = "Structure";

  meta = {
    description = "Universal structure alignment of monomeric and complex proteins and nucleic acids";
    homepage = "https://github.com/pylelab/USalign";
    # Custom permissive license: use/copy/modify/distribute for any purpose
    # provided the notices and references are retained; no SPDX equivalent.
    license = {
      fullName = "US-align license (permissive, BSD-like)";
      free = true;
      redistributable = true;
    };
    platforms = lib.platforms.unix;
    mainProgram = "USalign";
  };
}
