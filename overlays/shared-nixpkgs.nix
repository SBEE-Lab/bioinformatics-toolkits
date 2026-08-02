{ mkPackagesFor }:
final: _prev: {
  bioinformatics-toolkits = mkPackagesFor final;
}
