let
    pkgs = import <nixpkgs> {};
in
pkgs.stdenv.mkDerivation {
  name = "fscrypt-steamdeck-nix";

  buildInputs =
  [
    pkgs.fscrypt
  ];
}
