{
  lib,
  stdenv,
  fetchFromGitHub,
}:
stdenv.mkDerivation {
  pname = "usalign";
  version = "20260815";

  src = fetchFromGitHub {
    owner = "pylelab";
    repo = "USalign";
    rev = "613f7d1776ec71d8230a1bdc9aff11861c2aabee";
    hash = "sha256-+bpjznTPyAqiwBppYrierQ/Ok1t4RWGmDPtxB3igVYo=";
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
