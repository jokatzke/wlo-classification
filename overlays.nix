{ lib }:
rec {
  default = wlo-classification;

  # add additional dependencies not present in nixpkgs
  # (here, external resources)
  fix-nixpkgs = (
    final: prev: {
      gbert-base-metadata = final.fetchgit {
        url = "https://huggingface.co/deepset/gbert-base";
        rev = "e2073f52ebb8dd8b50ed5230a9752e251105c096";
        hash = "sha256-iRNhzt/VNkOErS1/slIQ0jS0472qNSlNNow9juzdu3w=";
        # do not fetch the files managed by git LFS, we only need the metadata
        fetchLFS = false;
      };
      wlo-classification-model = final.fetchFromGitLab {
        domain = "gitlab.gwdg.de";
        owner = "jopitz";
        repo = "wlo-classification-model";
        rev = "66661ad257969a66af632fc5b184765d0ef95fd8";
        hash = "sha256-CIZAbCH5JUAXOchxSByCxUO/p9jR1B+8CkIOoNOQtiA=";
      };
    }
  );

  # add the python library to all python environments
  python-lib = lib.composeExtensions fix-nixpkgs (
    final: prev: {
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (python-final: python-prev: { wlo-classification = python-final.callPackage ./python-lib.nix { }; })
      ];
    }
  );

  # add the standalone application without affecting the global scope of python
  # packages
  wlo-classification = lib.composeExtensions fix-nixpkgs (
    final: prev:
    let
      py-pkgs = final.python3Packages;
      wlo-classification-lib = py-pkgs.callPackage ./python-lib.nix { };
    in
    {
      wlo-classification = py-pkgs.callPackage ./package.nix {
        # inject the python library, rather than adding it to all of nixpkgs
        wlo-classification = wlo-classification-lib;
      };
    }
  );
}
