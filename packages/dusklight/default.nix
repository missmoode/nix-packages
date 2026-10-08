{
  lib,
  pkgs,
  sources,
  rustPlatform,
  curl,
}:

let
  symgen = rustPlatform.buildRustPackage {
    pname = "symgen";
    version = "1.3.6";

    src = sources.symgen;

    cargoLock.lockFile = "${sources.symgen}/Cargo.lock";

    postPatch = ''
      cat > build.rs <<'EOF'
      fn main() {
          println!("cargo:rustc-env=GIT_COMMIT_SHA=${sources.symgen.rev or "unknown"}");
      }
      EOF
    '';

    doCheck = false;
  };
in
pkgs.dusklight.overrideAttrs (old: {
  # The mod-enabled build has additional source dependencies.
  # Restrict this override to the architecture we've targeted.
  meta = (old.meta or { }) // {
    platforms = [ "x86_64-linux" ];
  };

  buildInputs = (old.buildInputs or [ ]) ++ [
    curl
  ];

  # Preserve the upstream Nixpkgs patch and prevent configuration
  # of in-tree mods, which require additional vendored sources.
  # Aside from adding luau.
  # This does not disable loading user-installed native mods.
  postPatch = (old.postPatch or "") + ''
    # Don't configure every in-tree mod.
    substituteInPlace CMakeLists.txt \
      --replace-fail \
      'if (DUSK_ENABLE_CODE_MODS AND CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)' \
      'if (DUSK_ENABLE_CODE_MODS AND CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR AND NOT DUSK_NIX_SKIP_IN_TREE_MODS)'

    # Build Luau Support independently of the other in-tree mods.
    substituteInPlace CMakeLists.txt \
      --replace-fail \
      'include(cmake/ModSDK.cmake)' \
      'include(cmake/ModSDK.cmake)
      add_subdirectory(mods/luau_runtime)'
  '';

  cmakeFlags =
    lib.filter (
      flag:
      !(lib.hasPrefix "-DDUSK_ENABLE_CODE_MODS:" flag || lib.hasPrefix "-DBOREALIS_HTTP_BACKEND:" flag)
    ) old.cmakeFlags
    ++ [
      (lib.cmakeBool "DUSK_ENABLE_CODE_MODS" true)
      (lib.cmakeBool "DUSK_NIX_SKIP_IN_TREE_MODS" true)
      (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_LUAU" "${sources.luau}")
      (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_LUABRIDGE3" "${sources.luabridge3}")
      (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_FUNCHOOK" "${sources.funchook}")

      (lib.cmakeFeature "SYMGEN_PATH" "${symgen}/bin/symgen")

      (lib.cmakeFeature "BOREALIS_HTTP_BACKEND" "curl")
    ];

  # Keep the linked binary intact after Symgen embeds its manifest.
  dontStrip = true;

  postInstall = (old.postInstall or "") + ''
    # Install Luau Support as a bundled, read-only mod.
    install -d "$out/share/dusklight/mods/dev.twilitrealm.luau"

    cp -r mods/luau_runtime/luau_runtime_stage/. \
      "$out/share/dusklight/mods/dev.twilitrealm.luau/"
  '';
})
