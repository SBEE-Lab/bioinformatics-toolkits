# treefmt hook: check that each Nushell file parses.
def main [...files: string] {
  for file in $files {
    let target = ($file | path expand --no-symlink)
    try {
      nu-check --debug $target | ignore
    } catch {|error|
      print -e $"nu-check: parse error in ($file)"
      print -e ($error.rendered? | default ($error.msg? | default "parse error"))
      exit 1
    }
  }
}
