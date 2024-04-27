{ pkgs ? import <nixpkgs> { } }:
with pkgs;
mkShell {
  buildInputs = [
    nixpkgs-fmt
    pkgs.kubectl
    pkgs.unstable.talosctl
    pkgs.kubernetes-helm
    pkgs.hcloud
    pkgs.unstable.cilium-cli
    pkgs.gettext
  ];

  shellHook = ''
    # ...
  '';
}
