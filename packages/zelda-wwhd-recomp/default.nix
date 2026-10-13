{
  lib,
  appimageTools,
  fetchurl,
}:

let
  pname = "zelda-wwhd-recomp";
  version = "0.2.13";

  src = fetchurl {
    url = "https://github.com/ZeldaWWHDRecomp/ZeldaWWHDRecomp/releases/download/v${version}/WindWakerHD-v${version}-linux-x86_64.AppImage";
    hash = "sha256-NNbwobn8DPZgF+jIF19yrKwQgzLah/o9AtHdg5vcBsY=";
  };

  appimageContents = appimageTools.extract {
    inherit pname version src;
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraPkgs = pkgs: [
    pkgs.python3
  ];

  extraInstallCommands = ''
    install -Dm444 \
      ${appimageContents}/wwhd.desktop \
      $out/share/applications/${pname}.desktop

    substituteInPlace $out/share/applications/${pname}.desktop \
      --replace-fail 'Exec=wind-waker-hd' 'Exec=${pname}'

    install -Dm444 \
      ${appimageContents}/wwhd.png \
      $out/share/pixmaps/wwhd.png
  '';

  meta = {
    description = "Native recompilation of The Legend of Zelda: The Wind Waker HD";
    homepage = "https://github.com/ZeldaWWHDRecomp/ZeldaWWHDRecomp";
    license = lib.licenses.mpl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = pname;
  };
}
