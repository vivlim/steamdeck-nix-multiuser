let
    pkgs = import <nixpkgs> {};
    nixGLPkgs = import (pkgs.fetchFromGitHub { owner="guibou"; repo="nixGL"; rev="047a34b2f087e2e3f93d43df8e67ada40bf70e5c"; sha256="4b3d2e5aca6abec84615b4fe5e645555acae5b9d78acd34b2efaeb7bc8c12cb5";}) {};

    # Provides a script that copies required files to ~/
    # from https://gist.github.com/adisbladis/187204cb772800489ee3dac4acdd9947
    podmanSetupScript = let
      containersConf = pkgs.writeText "containers.conf" ''
        [network]
        cni_plugin_dirs = [
          "${pkgs.cni-plugins}/bin" # use path in nix store for CNI plugins
        ]
      '';

      registriesConf = pkgs.writeText "registries.conf" ''
        [registries.search]
        registries = ['docker.io']
        [registries.block]
        registries = []
      '';
      storageConf = pkgs.writeText "storage.conf" ''
        [storage]
        driver = "overlay"
        # /run is too small on the steam deck! (~3GB)
        runroot = "/tmp/podman_run/containers/storage"
        # /var is *way* too small on the steam deck! (~230MB)
        graphroot = "/home/deck/.podman-containers/storage"
      '';
    in pkgs.writeScript "podman-setup" ''
      #!${pkgs.runtimeShell}

      if [ "$EUID" -eq 0 ]; then
        BASE=/etc/containers
      else
        BASE=~/.config/containers
      fi
      # Dont overwrite customised configuration
      if ! test -f $BASE/policy.json; then
        install -Dm555 ${pkgs.skopeo.src}/default-policy.json $BASE/policy.json
      fi
      if ! test -f $BASE/containers.conf; then
        install -Dm555 ${containersConf} $BASE/containers.conf
      fi
      if ! test -f $BASE/registries.conf; then
        install -Dm555 ${registriesConf} $BASE/registries.conf
      fi
      if ! test -f $BASE/storage.conf; then
        install -Dm555 ${storageConf} $BASE/storage.conf
      fi
    '';
in
pkgs.mkShell {
  name = "x11docker-steamdeck-nix";

  buildInputs =
  [
    pkgs.x11docker
    pkgs.tmux
    pkgs.podman
    pkgs.tini
    pkgs.buildah
    pkgs.runc
    pkgs.conmon
    pkgs.skopeo
    pkgs.slirp4netns
    pkgs.fuse-overlayfs
    pkgs.tini
    pkgs.weston
    pkgs.xwayland
    nixGLPkgs.nixGLIntel
  ];

  shellHook = ''
    ${podmanSetupScript}
  '';
}
