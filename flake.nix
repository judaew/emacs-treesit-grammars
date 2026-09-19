{
  description = "Pinned tree-sitter grammars for Emacs (treesit)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
  let
    systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
    forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
  in
  {
    lib = import ./lib.nix (import ./pins.nix);


    # This is used for CI checks, here is an example for manual
    # checks:
    # 1. nix flake check --all-systems -L
    # 2. nix build -L ".#emacs-treesit-bundle" --print-out-paths
    packages = forAllSystems (pkgs:
    (self.lib.grammars pkgs) // {
      emacs-treesit-bundle =
        self.lib.withGrammars {
          pkgs = pkgs;
          epkgs = pkgs.emacsPackagesFor pkgs.emacs-nox;
        };
      }
    );
    checks = self.packages;
  };
}
