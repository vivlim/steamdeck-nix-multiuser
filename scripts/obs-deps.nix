let
    pkgs = import <nixpkgs> {};
    nixGLPkgs = import (pkgs.fetchFromGitHub { owner="guibou"; repo="nixGL"; rev="047a34b2f087e2e3f93d43df8e67ada40bf70e5c"; sha256="4b3d2e5aca6abec84615b4fe5e645555acae5b9d78acd34b2efaeb7bc8c12cb5";}) {};
in
pkgs.stdenv.mkDerivation {
  name = "x11docker-steamdeck-nix";

  buildInputs =
  [
    pkgs.obs-studio
    pkgs.vaapiVdpau
    pkgs.gst_all_1.gst-vaapi
    pkgs.libvdpau-va-gl
    nixGLPkgs.nixGLIntel
  ];
}
