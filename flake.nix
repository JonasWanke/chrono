{
  inputs = {
    # https://github.com/NixOS/nixpkgs/pull/364980
    nixpkgs.url =
      "github:nixos/nixpkgs?ref=711e659590895f1de0ada40dbdc1eb5bae98a179";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs { inherit system; };
      in { devShell = with pkgs; mkShell { buildInputs = [ dart ]; }; });
}
