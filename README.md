# bioinformatics-toolkits

Nix package registry for bioinformatics.

## Usage

Run a tool directly without installing:

```bash
nix run github:SBEE-Lab/bioinformatics-toolkits#foldseek -- --help
```

Supported systems: `x86_64-linux`, `aarch64-linux`, `aarch64-darwin`.

### As a flake input

Pull individual packages from `packages.<system>` — these are built against this
repo's pinned `nixpkgs`, so results are reproducible:

```nix
{
  inputs.bio.url = "github:SBEE-Lab/bioinformatics-toolkits";

  outputs = { nixpkgs, bio, ... }: {
    # e.g. inside a devShell or package
    # bio.packages.x86_64-linux.foldseek
  };
}
```

### Via the overlay

Use `overlays.shared-nixpkgs` to build the package set against your own
`nixpkgs` instance:

```nix
{
  inputs.bio.url = "github:SBEE-Lab/bioinformatics-toolkits";

  outputs = { nixpkgs, bio, ... }:
    let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [ bio.overlays.shared-nixpkgs ];
        config.allowUnfree = true; # required by nupack, psipred, …
      };
    in
    {
      # pkgs.bioinformatics-toolkits.foldseek, …
    };
}
```

Overlay packages build against _your_ `nixpkgs`, not this repo's pin. That is
usually fine, but if your `nixpkgs` is far from ours a dependency may not line up
— pull from `packages.<system>` instead when you need the pinned build.

## Available Packages

<!-- BEGIN GENERATED PACKAGE DOCS -->

### Structure

<details>
<summary><strong>folddisco</strong> - Finding discontinuous motifs in protein structures</summary>

- **License**: GPL-3.0-or-later
- **Homepage**: https://github.com/steineggerlab/folddisco
- **Usage**: `nix run github:SBEE-Lab/bioinformatics-toolkits#folddisco -- --help`
- **Nix**: [packages/folddisco/package.nix](packages/folddisco/package.nix)

</details>
<details>
<summary><strong>foldmason</strong> - Multiple protein structure alignment at scale with FoldMason</summary>

- **License**: GPL-3.0-or-later
- **Homepage**: https://github.com/steineggerlab/foldmason
- **Usage**: `nix run github:SBEE-Lab/bioinformatics-toolkits#foldmason -- --help`
- **Nix**: [packages/foldmason/package.nix](packages/foldmason/package.nix)

</details>
<details>
<summary><strong>foldseek</strong> - Fast and sensitive protein structure search</summary>

- **License**: GPL-3.0-or-later
- **Homepage**: https://github.com/steineggerlab/foldseek
- **Usage**: `nix run github:SBEE-Lab/bioinformatics-toolkits#foldseek -- --help`
- **Nix**: [packages/foldseek/package.nix](packages/foldseek/package.nix)

</details>
<details>
<summary><strong>structty</strong> - Interactive, terminal-native protein structure viewer</summary>

- **License**: GPL-3.0-only
- **Homepage**: https://github.com/steineggerlab/StrucTTY
- **Usage**: `nix run github:SBEE-Lab/bioinformatics-toolkits#structty -- --help`
- **Nix**: [packages/structty/package.nix](packages/structty/package.nix)

</details>
<details>
<summary><strong>usalign</strong> - Universal structure alignment of monomeric and complex proteins and nucleic acids</summary>

- **License**: US-align license (permissive, BSD-like)
- **Homepage**: https://github.com/pylelab/USalign
- **Usage**: `nix run github:SBEE-Lab/bioinformatics-toolkits#usalign -- --help`
- **Nix**: [packages/usalign/package.nix](packages/usalign/package.nix)

</details>

### Sequence

<details>
<summary><strong>nupack</strong> - Analysis and design of nucleic acid structures, devices, and systems</summary>

- **License**: unfree
- **Homepage**: https://www.nupack.org
- **Usage**: `nix build github:SBEE-Lab/bioinformatics-toolkits#nupack`
- **Nix**: [packages/nupack/package.nix](packages/nupack/package.nix)

</details>
<details>
<summary><strong>psipred</strong> - PSIPRED V4 protein secondary structure prediction</summary>

- **License**: unfree
- **Homepage**: https://github.com/psipred/psipred
- **Usage**: `nix build github:SBEE-Lab/bioinformatics-toolkits#psipred`
- **Nix**: [packages/psipred/package.nix](packages/psipred/package.nix)

</details>
<details>
<summary><strong>thermompnn</strong> - Predict ddG stability changes of protein point mutants with a ProteinMPNN-based GNN</summary>

- **License**: MIT
- **Homepage**: https://github.com/Kuhlman-Lab/ThermoMPNN
- **Usage**: `nix run github:SBEE-Lab/bioinformatics-toolkits#thermompnn -- --help`
- **Nix**: [packages/thermompnn/package.nix](packages/thermompnn/package.nix)

</details>

### Evolution

<details>
<summary><strong>plmc</strong> - Infer Potts models (couplings) from a multiple sequence alignment by pseudo-likelihood maximization</summary>

- **License**: MIT
- **Homepage**: https://github.com/debbiemarkslab/plmc
- **Usage**: `nix run github:SBEE-Lab/bioinformatics-toolkits#plmc -- --help`
- **Nix**: [packages/plmc/package.nix](packages/plmc/package.nix)

</details>
<details>
<summary><strong>rate4site</strong> - Detect conserved amino-acid sites by computing the relative evolutionary rate for each site</summary>

- **License**: GPL-2.0-or-later
- **Homepage**: https://www.tau.ac.il/~itaymay/cp/rate4site.html
- **Usage**: `nix run github:SBEE-Lab/bioinformatics-toolkits#rate4site -- --help`
- **Nix**: [packages/rate4site/package.nix](packages/rate4site/package.nix)

</details>

### Data

<details>
<summary><strong>biomcp</strong> - Biomedical CLI and MCP server for biomedical data sources</summary>

- **License**: MIT
- **Homepage**: https://biomcp.org
- **Usage**: `nix run github:SBEE-Lab/bioinformatics-toolkits#biomcp -- --help`
- **Nix**: [packages/biomcp/package.nix](packages/biomcp/package.nix)

</details>

### Library

<details>
<summary><strong>biotite</strong> - Comprehensive library for computational molecular biology</summary>

- **License**: BSD-3-Clause
- **Homepage**: https://www.biotite-python.org
- **Usage**: `nix build github:SBEE-Lab/bioinformatics-toolkits#biotite`
- **Nix**: [packages/biotite/package.nix](packages/biotite/package.nix)

</details>

<!-- END GENERATED PACKAGE DOCS -->

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Run `nix fmt` before committing
4. Submit a pull request

## License

Individual tools are licensed under their respective licenses.

The Nix packaging code in this repository is licensed under MIT.
