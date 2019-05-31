{ pkgs ? import <nixpkgs> {} }:

with pkgs;
let
  pp2n = import (pkgs.fetchFromGitHub {
    owner = "justinwoo";
    repo = "psc-package2nix";
    rev = "cc48ccd64862366a44b4185a79de321f93755782";
    sha256 = "0cvd1v3d376jiwh4rfhlyijxw3j6jp9rkm9hdb7k7sjxqs1dsviv";
  }) { inherit pkgs; };
  easyPS = import (pkgs.fetchFromGitHub {
    owner = "justinwoo";
    repo = "easy-purescript-nix";
    rev = "bad807ade1314420a52c589dbc3d64d3c9b38480";
    sha256 = "099dpxrpch8cgy310svrpdcad2y1qdl6l782mjpcgn3rqgj62vsf";
  });
in stdenv.mkDerivation {
  
  name = "hipster-stack";

  buildInputs = [
      pp2n
      rustup
      easyPS.spago
      purescript
      psc-package
  ];

  shellHook = ''
    fish -l
  '';
}