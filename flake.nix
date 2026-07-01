{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      rust-overlay,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };
        rustToolchain = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            rustToolchain
            pkgs.trunk
            pkgs.python314
            pkgs.python314Packages.httpx
            pkgs.python314Packages.beautifulsoup4
            pkgs.python314Packages.types-beautifulsoup4
            pkgs.python314Packages.tqdm
            pkgs.python314Packages.html5lib
            pkgs.tree
            pkgs.typst
          ];
          UV_PYTHON = "${pkgs.python314}/bin/python";
        };
      }
    );
}
