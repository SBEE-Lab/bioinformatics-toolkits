#!/usr/bin/env nix
#! nix shell --inputs-from .# nixpkgs#nushell --command nu

# Generate package documentation in README.md from evaluated Nix metadata.

const BEGIN_MARKER = "<!-- BEGIN GENERATED PACKAGE DOCS -->"
const END_MARKER = "<!-- END GENERATED PACKAGE DOCS -->"
const FLAKE_REF = "github:SBEE-Lab/bioinformatics-toolkits"
const CATEGORY_ORDER = ["Structure" "Sequence" "Evolution" "Data" "Library"]

def all-packages-metadata [nix_file: string, metadata_json?: string]: nothing -> table {
  let data = if $metadata_json == null {
    ^nix eval --json --file $nix_file | from json
  } else {
    open $metadata_json
  }
  $data
  | transpose package meta
  | where meta != null
  | sort-by package
}

def package-doc [package: string, meta: record]: nothing -> string {
  let description = ($meta.description? | default "No description available")
  let license = ($meta.license? | default "Check package")
  mut lines = [
    "<details>"
    $"<summary><strong>($package)</strong> - ($description)</summary>"
    ""
    $"- **License**: ($license)"
  ]

  let homepage = ($meta.homepage? | default null)
  if $homepage != null and $homepage != "" {
    $lines = ($lines | append $"- **Homepage**: ($homepage)")
  }

  let main_program = ($meta.mainProgram? | default null)
  if $main_program != null {
    $lines = ($lines | append $"- **Usage**: `nix run ($FLAKE_REF)#($package) -- --help`")
  } else {
    $lines = ($lines | append $"- **Usage**: `nix build ($FLAKE_REF)#($package)`")
  }
  $lines = ($lines | append $"- **Nix**: [packages/($package)/package.nix]\(packages/($package)/package.nix\)")

  if ($"packages/($package)/README.md" | path exists) {
    $lines = ($lines | append $"- **Documentation**: See [packages/($package)/README.md]\(packages/($package)/README.md\) for detailed usage")
  }

  $lines = ($lines | append "" | append "</details>")
  $lines | str join "\n"
}

def generate-all-docs [rows: table]: nothing -> string {
  let invalid = ($rows | where {|r| ($r.meta.category? | default "") not-in $CATEGORY_ORDER })
  if ($invalid | is-not-empty) {
    let first = ($invalid | first)
    print -e $"Package '($first.package)' has invalid category '($first.meta.category? | default "")'; expected one of: ($CATEGORY_ORDER | str join ', ')"
    exit 1
  }

  let by_category = ($rows | group-by {|r| $r.meta.category })
  ($CATEGORY_ORDER | where {|category| $category in ($by_category | columns) })
  | each {|category|
      let docs = ($by_category | get $category | each {|row| package-doc $row.package $row.meta } | str join "\n")
      $"### ($category)\n\n($docs)"
    }
  | str join "\n\n"
}

def rendered-readme [readme_path: string, docs: string]: nothing -> record {
  let content = (open --raw $readme_path | decode utf-8)
  let begin_idx = ($content | str index-of $BEGIN_MARKER)
  let end_idx = ($content | str index-of $END_MARKER)
  if $begin_idx == -1 or $end_idx == -1 {
    print -e $"Could not find generated package markers in ($readme_path)"
    exit 1
  }
  if $end_idx < $begin_idx {
    print -e "END marker appears before BEGIN marker"
    exit 1
  }
  let before = ($content | split row $BEGIN_MARKER | first)
  let after = ($content | split row $END_MARKER | last)
  {
    current: $content
    generated: $"($before)($BEGIN_MARKER)\n\n($docs)\n\n($END_MARKER)($after)"
  }
}

def main [--check, --metadata-json: string] {
  let script_dir = $env.FILE_PWD
  let nix_file = ($script_dir | path join "generate-package-docs.nix")
  let readme_path = ($script_dir | path dirname | path join "README.md")
  let rows = (all-packages-metadata $nix_file $metadata_json)
  let rendered = (rendered-readme $readme_path (generate-all-docs $rows))

  if $rendered.current == $rendered.generated {
    print $"No changes to ($readme_path)"
  } else if $check {
    print -e "README.md package docs are stale; run scripts/generate-package-docs.nu"
    exit 1
  } else {
    $rendered.generated | save --force $readme_path
    print $"Updated ($readme_path)"
  }
}
