{ stdenv, fetchurl, unzip, makeWrapper, jre }:

stdenv.mkDerivation rec {
  pname = "conan";
  version = "1.0";
  src = fetchurl {
    url = "https://github.com/nonilole/Conan/files/1042290/Conan.zip";
    sha256 = "c2151bdd0643b04ec3065986a424135ab93d552fc2d2f23883712fe036436dbd";
  };
  # Workaround for "unpacker appears to have produced no directories"
  setSourceRoot = "sourceRoot=$PWD";

  nativeBuildInputs = [ unzip makeWrapper ];

  installPhase = ''
    mkdir -p $out/{bin,lib}
    install -m644 Conan.jar $out/lib
    makeWrapper ${jre}/bin/java $out/bin/${pname} \
      --add-flags "-jar $out/lib/Conan.jar"
  '';

  meta = with stdenv.lib; {
    description = "A proof editor for first order logic";
    homepage = "https://github.com/nonilole/Conan";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
