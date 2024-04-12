{
  description = "A Python package defined as a Nix Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
    openapi-checks = {
      url = "github:openeduhub/nix-openapi-checks";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    {
      # define an overlay to add wlo-classification to nixpkgs
      overlays = import ./overlays.nix {inherit (nixpkgs) lib;};
    } //
    # tensorflow is currently marked as broken on darwin
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
      let
        # import the packages from nixpkgs
        pkgs = import nixpkgs {
          inherit system;
          # some dependencies, such as tensorflow, use unfree licenses
          config.allowUnfree = true;
          overlays = [
            self.outputs.overlays.default
            self.outputs.overlays.python-lib
          ];
        };
      in
      {
        # the packages that we can build
        packages = rec {
          inherit (pkgs) wlo-classification;
          default = wlo-classification;
          docker = pkgs.callPackage ./docker.nix {};
          python-lib = pkgs.python3Packages.wlo-classification;
        };
        # the development environment
        devShells.default = pkgs.callPackage ./shell.nix {};
        # checks
        checks = {
          openapi-valid = self.inputs.openapi-checks.lib.${system}.test-service {
            service-bin = "${self.packages.${system}.wlo-classification}/bin/wlo-classification";
            memory-size = 4 * 1024;
            service-port = 8080;
            openapi-domain = "/openapi.json";
          };
        };
      });
}
