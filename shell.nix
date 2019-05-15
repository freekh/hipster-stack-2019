{ pkgs ? import <nixpkgs> {} }:

with pkgs;

stdenv.mkDerivation {
  name = "commands-nix";

  buildInputs = [
      rustup
      purescript
  ];

  shellHook = ''
    fish -l
  '';
}