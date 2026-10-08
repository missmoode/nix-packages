{
  lib,
  stdenv,
  fetchurl,
  appimageTools,
}:
let
  release = builtins.fromJSON (builtins.readFile ./release.json);
  pname = "dusklight";
  inherit (release) version;
  asset = release.assets.${stdenv.hostPlatform.system};

  src = fetchurl {
    url = "https://github.com/TwilitRealm/dusklight/releases/download/v${version}/Dusklight-v${version}-linux-${asset.arch}.AppImage";
    hash = asset.hash;
  };
in
appimageTools.wrapType2 (finalAttrs: {
  inherit pname version src;

  extraInstallCommands = ''
    install -Dm644 \
      "${finalAttrs.contents}/usr/share/applications/dev.twilitrealm.dusk.desktop" \
      "$out/share/applications/dev.twilitrealm.dusk.desktop"

    mkdir -p "$out/share/icons"
    cp -r "${finalAttrs.contents}/usr/share/icons/hicolor" "$out/share/icons/"
  '';

  meta = {
    description = "Reverse-engineered reimplementation of The Legend of Zelda: Twilight Princess";
    homepage = "https://github.com/TwilitRealm/dusklight";
    changelog = "https://github.com/TwilitRealm/dusklight/releases/tag/v${version}";
    license = lib.licenses.cc0;
    mainProgram = pname;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
})
