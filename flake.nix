{
  description = "hcloud-talos";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    flake-utils.lib.eachDefaultSystem
      (system:
        let pkgs = nixpkgs.legacyPackages.${system}.extend (
          final: prev: {
              unstable = inputs.nixpkgs-unstable.legacyPackages."${system}";
              x86_64 = nixpkgs.legacyPackages."x86_64-linux";
              x86_64_unstable = inputs.nixpkgs-unstable.legacyPackages."x86_64-linux";
          }
        ); in
        {
          devShells.default = import ./shell.nix { inherit pkgs; };
        }
      );
}
