{
  lib,
  stdenv,
  fetchFromGitHub,
  zlib,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "thermonucleotideblast";
  version = "2.77";

  src = fetchFromGitHub {
    owner = "jgans";
    repo = "thermonucleotideBLAST";
    tag = "v${finalAttrs.version}";
    hash = "sha256-PB3D2J5qXpnwvrrPjPkaoqQNLR2I6/915TVHVJzM+XM=";
  };

  buildInputs = [ zlib ];
  preBuild = ''
    makeFlagsArray+=("FLAGS=-O3 -Wall -std=c++14")
  '';

  # FASTA and GenBank searches need neither MPI nor the NCBI BLAST toolkit.
  makeFlags = [
    "CC=${stdenv.cc.targetPrefix}c++"
    "OPENMP="
    "BLAST_DIR="
  ];
  enableParallelBuilding = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 tntblast $out/bin/tntblast
    runHook postInstall
  '';

  # The README's Marburg assay must reproduce its documented 147-base amplicon.
  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    printf '>marburg_fixture\nTTCCCCTTTGGAGGCATCCAAGCGATGGGCTTTCAGGACAGGTGTACCTCCCAAGAATGTTGAGTATACAGAAGGGGAGGAAGCCAAAACATGCTACAATATAAGTGTAACGGATCCCTCTGGAAAATCCTTGCTGTTGGATCCTCC\n' > target.fa
    printf 'gibb-marburg\tTTCCCCTTTGGAGGCATC\tGGAGGATCCAACAGCAAGG\tCGATGGGCTTTCAGGACAGGTGT\n' > primers.tsv
    $out/bin/tntblast -i primers.tsv -d target.fa -e 40 -E 45 -l 200 \
      --max-mismatch 0 --max-gap 0 --single-primer-pcr F -m 1 -o products.fa
    grep -q 'TTCCCCTTTGGAGGCATCCAAGCGATGGGCTTTCAGGACAGGTGTACCTCCCAAGAATGTTGAGTATACAGAAGGGGAGGAAGCCAAAACATGCTACAATATAAGTGTAACGGATCCCTCTGGAAAATCCTTGCTGTTGGATCCTCC' products.fa
    runHook postInstallCheck
  '';

  passthru.category = "Sequence";

  meta = {
    description = "Search DNA targets for primer and probe binding using duplex thermodynamics";
    homepage = "https://github.com/jgans/thermonucleotideBLAST";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.unix;
    mainProgram = "tntblast";
  };
})
