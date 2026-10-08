{
  description = "Personal Nix packages and overrides";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      lib = nixpkgs.lib;
      systems = [ "x86_64-linux" "aarch64-linux" ];
      packagesDir = ./packages;

      packageNames = lib.attrNames (
        lib.filterAttrs (
          name: type:
          type == "directory"
          && builtins.pathExists (packagesDir + "/${name}/default.nix")
        ) (builtins.readDir packagesDir)
      );

      reservedNames = [ "pkgs" "callPackage" "newScope" "overrideScope" "packages" ];
      conflicts = lib.intersectLists reservedNames packageNames;
    in
    assert lib.assertMsg (conflicts == [ ])
      "Reserved package names: ${lib.concatStringsSep ", " conflicts}";
    {
      packages = lib.genAttrs systems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          scope = lib.makeScope pkgs.newScope (
            self:
            { inherit pkgs; }
            // lib.genAttrs packageNames (
              name: self.callPackage (packagesDir + "/${name}/default.nix") { }
            )
          );
        in
        lib.filterAttrs
          (_: package: lib.meta.availableOn pkgs.stdenv.hostPlatform package)
          (lib.genAttrs packageNames (name: scope.${name}))
      );
    };
}
