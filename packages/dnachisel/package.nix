{
  lib,
  python3Packages,
  fetchFromGitHub,
  fetchPypi,
  allPackages,
  bowtie,
  blast,
  stdenv,
}:
let
  pdfReports = python3Packages.buildPythonPackage (finalAttrs: {
    pname = "pdf-reports";
    version = "0.3.9";
    format = "wheel";
    src = fetchPypi {
      pname = "pdf_reports";
      inherit (finalAttrs) version;
      format = "wheel";
      python = "py3";
      dist = "py3";
      hash = "sha256-MK/pl9MCZnP77/2Wu/Ceogv4rQ7Mlqz9MALK0KOEdUo=";
    };
    dependencies = with python3Packages; [
      pypugjs
      jinja2
      weasyprint
      beautifulsoup4
      pandas
      markdown
    ];
    pythonRemoveDeps = [ "backports.functools-lru-cache" ];
    doCheck = false;
    pythonImportsCheck = [ "pdf_reports" ];
  });

  sequenticon = python3Packages.buildPythonPackage (finalAttrs: {
    pname = "sequenticon";
    version = "0.1.8";
    format = "wheel";
    src = fetchPypi {
      inherit (finalAttrs) pname version;
      format = "wheel";
      python = "py3";
      dist = "py3";
      hash = "sha256-nkaqzDWMFWW368NFVjeGaOb0wqWBZTz/sZ9oAmTExOo=";
    };
    dependencies = with python3Packages; [
      biopython
      pydenticon
      flametree
      pdfReports
      allPackages."snapgene-reader"
    ];
    doCheck = false;
    pythonImportsCheck = [ "sequenticon" ];
  });

  reportsDependencies = with python3Packages; [
    pdfReports
    sequenticon
    matplotlib
    allPackages."dna-features-viewer"
    pandas
  ];

  # nixpkgs' 0.1.6 source bootstraps setuptools through a bundled ez_setup.py,
  # which is incompatible with Python 3.14. Setuptools is already supplied by
  # buildPythonPackage, so remove that obsolete bootstrap for the test helper.
  genomeCollector = python3Packages."genome-collector".overridePythonAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      sed -i '1,2d' setup.py
    '';
  });
in
python3Packages.buildPythonPackage (finalAttrs: {
  pname = "dnachisel";
  version = "3.2.16";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "Edinburgh-Genome-Foundry";
    repo = "DnaChisel";
    tag = "v${finalAttrs.version}";
    hash = "sha256-F+G7dwehUCHYKSGsLQR4OZg2NQ4677XMlN6jOcmz8No=";
  };

  postPatch = ''
    # PDF byte sizes vary slightly with the packaged rendering stack.
    substituteInPlace tests/test_constraints_reports.py \
      --replace-fail "len(pdf_data) < 80000" "len(pdf_data) < 90000"
    substituteInPlace dnachisel/biotools/bowtie.py \
      --replace-fail '["bowtie-build",' '["${bowtie}/bin/bowtie-build-s",' \
      --replace-fail '["bowtie"]' '["${bowtie}/bin/bowtie-align-s"]' \
      --replace-fail 'parameters += [bowtie_index_path]' \
        'parameters += ["-x", bowtie_index_path]'
    substituteInPlace dnachisel/biotools/blast_sequence.py \
      --replace-fail '"blastn",' '"${blast}/bin/blastn",'
  ''
  + lib.optionalString stdenv.hostPlatform.isDarwin ''
    # Bowtie 1.3.1 traps on Darwin when --best is combined with -k 1.
    # AvoidMatches still detects any hit allowed by -v without --best, but
    # the selected hit's mismatch count may differ when several hits qualify.
    substituteInPlace dnachisel/biotools/bowtie.py \
      --replace-fail 'parameters += ["--best", "-k", "1"]' \
        'parameters += ["-k", "1"]'
  '';

  build-system = [ python3Packages.setuptools ];

  dependencies =
    (with python3Packages; [
      biopython
      docopt
      flametree
      numpy
      proglog
      python-codon-tables
    ])
    ++ reportsDependencies;

  optional-dependencies.reports = reportsDependencies;

  nativeCheckInputs =
    (with python3Packages; [
      pytestCheckHook
      genomeCollector
    ])
    ++ reportsDependencies
    ++ [
      allPackages."primer3-py"
      bowtie
      blast
    ];

  enabledTestPaths = [ "tests" ];
  disabledTests = [
    # Download genomes from NCBI, then build BLAST/Bowtie indexes.
    "test_avoid_phage_blast_matches"
    "test_avoid_matches_with_phage"
  ];

  pythonImportsCheck = [ "dnachisel" ];

  passthru.category = "Sequence";

  meta = {
    description = "Optimize DNA sequences under constraints";
    homepage = "https://github.com/Edinburgh-Genome-Foundry/DnaChisel";
    changelog = "https://github.com/Edinburgh-Genome-Foundry/DnaChisel/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    mainProgram = "dnachisel";
  };
})
