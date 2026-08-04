{
  lib,
  config,
  stdenv,
  fetchFromGitHub,
  python3,
  makeWrapper,
  # Keep CUDA selection consistent across the Python environment.
  cudaSupport ? config.cudaSupport,
}:
let
  # Avoid mixing the CPU and CUDA torch propagated by Python dependencies.
  python = python3.override {
    packageOverrides =
      _: super:
      lib.optionalAttrs cudaSupport {
        # super.torchWithCuda recurses through the overridden fixpoint.
        torch = super.torch.override {
          cudaSupport = true;
          triton = super.triton-cuda;
          rocmSupport = false;
        };
      };
  };

  # Upstream imports training dependencies during inference.
  pythonEnv = python.withPackages (
    ps: with ps; [
      torch
      pytorch-lightning
      torchmetrics
      omegaconf
      biopython
      pandas
      numpy
      tqdm
      wandb
    ]
  );
in
stdenv.mkDerivation (_finalAttrs: {
  pname = "thermompnn";
  # No upstream tags/releases; track the main-branch HEAD by commit date.
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "Kuhlman-Lab";
    repo = "ThermoMPNN";
    rev = "2b04fd370e399911b1fa5848112cc9013f084110";
    hash = "sha256-93j6fd/jmHIarolUlbUM4ugHXrBOn3adnZ7SRHf+FXc=";
  };

  nativeBuildInputs = [ makeWrapper ];

  # Upstream is a clone-and-run repository without packaging metadata.
  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/thermompnn $out/bin
    cp -r . $out/share/thermompnn/

    # Repoint the authors' cluster path to the installed model weights.
    substituteInPlace $out/share/thermompnn/local.yaml \
      --replace-fail '/proj/kuhl_lab/ThermoMPNN' $out/share/thermompnn

    # Expose both import roots and default to the bundled checkpoint.
    makeWrapper ${pythonEnv}/bin/python3 $out/bin/thermompnn \
      --add-flags $out/share/thermompnn/analysis/custom_inference.py \
      --add-flags "--model_path $out/share/thermompnn/models/thermoMPNN_default.pt" \
      --prefix PYTHONPATH : "$out/share/thermompnn:$out/share/thermompnn/analysis"

    runHook postInstall
  '';

  # Exercise inference and the bundled checkpoint on a small PDB fragment.
  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    cp ${./test-fragment.pdb} test.pdb
    $out/bin/thermompnn --pdb test.pdb --chain A --out_dir out
    out_csv=$(echo out/ThermoMPNN_inference_*.csv)
    test -s "$out_csv" || { echo "ThermoMPNN produced no/empty output CSV"; exit 1; }
    echo "install check OK: $(wc -l < "$out_csv") rows in $out_csv"

    runHook postInstallCheck
  '';

  passthru.category = "Sequence";

  meta = {
    description = "Predict ddG stability changes of protein point mutants with a ProteinMPNN-based GNN";
    homepage = "https://github.com/Kuhlman-Lab/ThermoMPNN";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "thermompnn";
  };
})
