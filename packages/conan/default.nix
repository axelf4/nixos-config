{ lib, stdenv, fetchurl, unzip, makeDesktopItem, makeWrapper, jre }:

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
    mkdir -pv $out/{bin,lib,share/applications}
    install -m644 Conan.jar $out/lib
    makeWrapper ${jre}/bin/java $out/bin/${pname} \
      --add-flags "-jar $out/lib/Conan.jar"
    cp -av $desktopItem/share/applications/* $out/share/applications/
  '';

  desktopItem = makeDesktopItem {
    name = pname;
    exec = pname;
    icon = fetchurl {
      url = "https://raw.githubusercontent.com/nonilole/Conan/master/src/icon.png";
      sha256 = "c340cd0554f917a1d1c16d1cdfe151bad4d294b31601f2a6a91d44ba4aa8000e";
    };
    desktopName = "Conan";
    genericName = "Proof Editor";
    comment = meta.description;
    categories = "Education";
  };

  meta = with lib; {
    description = "A proof editor for first order logic";
    homepage = "https://github.com/nonilole/Conan";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
