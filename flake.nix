{
  description = "Pinned tree-sitter grammars for Emacs (treesit)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
  let
    systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
  in
  {
    lib = import ./lib.nix (import ./pins.nix);

    # nix build .#tree-sitter-rust
    # nix flake check
    packages = forAllSystems (pkgs: self.lib.grammars pkgs);
    checks = self.packages;
  };
}
