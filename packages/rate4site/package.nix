{
  lib,
  stdenv,
  fetchurl,
  perl,
}:
stdenv.mkDerivation {
  pname = "rate4site";
  version = "3.0.0";

  # The original distribution is unavailable; Debian preserves the GPL release
  # used by standalone ConSurf as an immutable snapshot.
  src = fetchurl {
    url = "https://snapshot.debian.org/file/837fb82c4ac368ebc64a5d8697706be3b0679829";
    name = "rate4site-3.0.0.orig.tar.gz";
    hash = "sha256-X3SBMbwtEDg8NcMUGoNe+k7B5wiM2diXDoAkAhqlCaw=";
  };

  nativeBuildInputs = [ perl ];

  # 2013-era C++ predates modern gcc/clang language defaults.
  env.CXXFLAGS = "-O2 -std=gnu++98 -fpermissive -w";

  enableParallelBuilding = true;

  # The primary binary uses extended-range floats to avoid likelihood underflow.

  passthru = {
    category = "Evolution";
    # Frozen upstream with an immutable source snapshot.
    skipUpdate = true;
  };

  meta = {
    description = "Detect conserved amino-acid sites by computing the relative evolutionary rate for each site";
    homepage = "https://www.tau.ac.il/~itaymay/cp/rate4site.html";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.unix;
    mainProgram = "rate4site";
  };
}
