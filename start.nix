{ pkgs ? import <nixpkgs> {} }:

with pkgs;
let
  spago = (import (pkgs.fetchFromGitHub {
    owner = "justinwoo";
    repo = "easy-purescript-nix";
    rev = "bad807ade1314420a52c589dbc3d64d3c9b38480";
    sha256 = "099dpxrpch8cgy310svrpdcad2y1qdl6l782mjpcgn3rqgj62vsf";
    })).spago;
in stdenv.mkDerivation {
  
  name = "hipster-stack";
  
  RUSTUP_TOOLCHAIN = "1.35.0";

  buildInputs = [

  ];

}
