{
  description = "Personal Nix packages and overrides";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    funchook = {
      url = "git+https://github.com/kubo/funchook.git?ref=refs/tags/v1.1.3&submodules=1";
      flake = false;
    };

    symgen = {
      url = "github:encounter/symgen/v1.3.6";
      flake = false;
    };

    luau = {
      url = "github:luau-lang/luau/0.734";
      flake = false;
    };

    luabridge3 = {
      url = "github:TwilitRealm/LuaBridge3/twilit-v1";
      flake = false;
    };
  };

  outputs =
    inputs@{ nixpkgs, ... }:
    let
      lib = nixpkgs.lib;

      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forAllSystems = f: lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

      packagesDir = ./packages;

      packageNames = lib.attrNames (
        lib.filterAttrs (
          name: type: type == "directory" && builtins.pathExists (packagesDir + "/${name}/default.nix")
        ) (builtins.readDir packagesDir)
      );

      reservedNames = [
        "pkgs"
        "sources"
        "callPackage"
        "newScope"
        "overrideScope"
        "packages"
      ];

      conflicts = lib.intersectLists reservedNames packageNames;

      sources = builtins.removeAttrs inputs [
        "self"
        "nixpkgs"
      ];
    in
    assert lib.assertMsg (
      conflicts == [ ]
    ) "Reserved package names: ${lib.concatStringsSep ", " conflicts}";
    {
      packages = forAllSystems (
        pkgs:
        let
          scope = lib.makeScope pkgs.newScope (
            self:
            {
              inherit pkgs sources;
            }
            // lib.genAttrs packageNames (name: self.callPackage (packagesDir + "/${name}") { })
          );
        in
        lib.filterAttrs (_: package: lib.meta.availableOn pkgs.stdenv.hostPlatform package) (
          lib.genAttrs packageNames (name: scope.${name})
        )
      );
    };
}
