{
  lib,
  stdenv,
  fetchFromGitHub,
  perl,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "primer3";
  version = "2.6.1";

  src = fetchFromGitHub {
    owner = "primer3-org";
    repo = "primer3";
    tag = "v${finalAttrs.version}";
    hash = "sha256-iIEzvQn0kilxkn1UXG1kCGaHH4PEp1qSLnIaZrTFVug=";
  };

  sourceRoot = "${finalAttrs.src.name}/src";

  # This fallback declaration for pre-ANSI SunOS conflicts with modern libc.
  postPatch = ''
    substituteInPlace read_boulder.c \
      --replace-fail "extern double strtod();" ""
  '';

  nativeCheckInputs = [ perl ];

  makeFlags = [
    "CC=${stdenv.cc.targetPrefix}cc"
    "CXX=${stdenv.cc.targetPrefix}c++"
    "AR=${stdenv.cc.targetPrefix}ar"
    "RANLIB=${stdenv.cc.targetPrefix}ranlib"
  ];

  enableParallelBuilding = true;

  doCheck = true;
  preCheck = "chmod -R u+w ../test";

  installPhase = ''
    runHook preInstall

    install -Dm755 -t $out/bin \
      amplicon3_core long_seq_tm_test ntdpal ntthal oligotm primer3_core primer3_masker
    install -dm755 $out/share/primer3
    cp -r primer3_config $out/share/primer3/
    cp -r ../kmer_lists ../settings_files $out/share/primer3/
    install -Dm644 primer3_manual.htm $out/share/doc/primer3/primer3_manual.htm

    runHook postInstall
  '';

  # Exercise installed binaries and ensure the separately installed
  # thermodynamic parameter tables can be loaded outside the source tree.
  doInstallCheck = true;
  installCheckPhase = ''
        runHook preInstallCheck

        test "$($out/bin/oligotm ATGCGCATGCGCATGCGCAT | cut -d. -f1)" -ge 55
        test -n "$($out/bin/ntdpal -s ATGCATGC GCATGCAT g)"
        test -n "$($out/bin/amplicon3_core ATGCGCATGCGCATGCGCAT)"

        cat > primer3-input <<EOF
    SEQUENCE_ID=installed-thermodynamic-data
    SEQUENCE_TEMPLATE=GCTAGCTAGCTACGATCGATCGTACGATCGATGCTAGCTAGCATCGATCGATCGTACGATCGATGCTAGCTAGCTACGATCGATCGTACGATCGATGCTAGCTAGCATCGATCGATCGTACGATCGATGC
    PRIMER_TASK=generic
    PRIMER_PICK_LEFT_PRIMER=1
    PRIMER_PICK_INTERNAL_OLIGO=0
    PRIMER_PICK_RIGHT_PRIMER=1
    PRIMER_OPT_SIZE=20
    PRIMER_MIN_SIZE=18
    PRIMER_MAX_SIZE=24
    PRIMER_PRODUCT_SIZE_RANGE=80-120
    PRIMER_THERMODYNAMIC_PARAMETERS_PATH=$out/share/primer3/primer3_config
    =
    EOF
        $out/bin/primer3_core < primer3-input > primer3-output
        grep -q '^PRIMER_LEFT_0_SEQUENCE=' primer3-output
        grep -q '^PRIMER_RIGHT_0_SEQUENCE=' primer3-output

        runHook postInstallCheck
  '';

  passthru.category = "Sequence";

  meta = {
    description = "PCR primer design and oligonucleotide analysis tools";
    homepage = "https://github.com/primer3-org/primer3";
    changelog = "https://github.com/primer3-org/primer3/releases/tag/v${finalAttrs.version}";
    license = [
      lib.licenses.gpl2Plus
      lib.licenses.gpl3Only
    ];
    platforms = lib.platforms.unix;
    mainProgram = "primer3_core";
  };
})
