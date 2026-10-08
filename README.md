# Personal Nix packages

The root flake automatically exposes `packages/<name>/default.nix` as `.#<name>` on supported systems. These derivations may also depend on other packages in the same scope.

## Dusklight

`packages/dusklight/default.nix` packages the *official upstream AppImage* rather than compiling Dusklight from source. Upstream's release build includes the native mod loader, Luau Support, and online mod browser. Nixpkgs' `appimageTools.wrapType2` runs it in an FHS environment on NixOS. This differs from the previous Nix-native patched derivation.

Update: `python3 packages/dusklight/update.py`; this updates the version and both platform hashes from GitHub's release metadata. Then run `nix build -L .#dusklight` and test the executable. `nix flake update` updates Nixpkgs, not Dusklight releases.

A new package needs only `packages/<name>/default.nix`. Source-built packages remain supported using standard Nixpkgs conventions.
