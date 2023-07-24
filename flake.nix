{
  description = "A Python package defined as a Nix Flake";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      projectDir = self;
      # import the packages from nixpkgs
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      # the python version we are using
      python = pkgs.python310;

      ### create the python installation for the package
      python-packages-build = py-pkgs:
        with py-pkgs; [jupyter
                       numpy
                       scikit-learn
                       pandas
                       seaborn
                       nltk
                       tensorflow
                       tensorflow-datasets
                       cherrypy
                       transformers
                       keras
                      ];
      python-build = python.withPackages python-packages-build;

      ### create the python installation for development
      # the development installation contains all build packages,
      # plus some additional ones we do not need to include in production.
      python-packages-devel = py-pkgs:
        with py-pkgs; [ipython
                       jupyter
                       black
                      ] ++ (python-packages-build py-pkgs);
      python-devel = python.withPackages python-packages-devel;

      ### create the python package
      # fetch an external resource for NLTK
      nltk-stopwords = pkgs.fetchzip {
        url = "https://github.com/nltk/nltk_data/raw/5db857e6f7df11eabb5e5665836db9ec8df07e28/packages/corpora/stopwords.zip";
        sha256 = "sha256-tX1CMxSvFjr0nnLxbbycaX/IBnzHFxljMZceX5zElPY=";
      };
      # build the application itself
      python-app = python-build.pkgs.buildPythonApplication {
        pname = "wlo-classification";
        version = "0.1.0";
        src = projectDir;
        propagatedBuildInputs = [python-build];
        preBuild = ''
          ${pkgs.coreutils}/bin/mkdir -p \
            $out/nltk_data/corpora/stopwords &&

          ${pkgs.coreutils}/bin/cp -r \
            ${nltk-stopwords}/* \
            $out/nltk_data/corpora/stopwords
        '';
      };
      
      ### build the docker image
      docker-img = pkgs.dockerTools.buildImage {
        name = python-app.pname;
        tag = python-app.version;
        config = {
          WorkingDir = "/";
        };
        # copy the binaries and nltk_data of the application into the image
        copyToRoot = pkgs.buildEnv {
          name = "image-root";
          paths = [ python-app pkgs.bash pkgs.coreutils ];
          pathsToLink = [ "/bin" "/nltk_data" ];
        };
      };

    in rec {
      # the packages that we can build
      packages.${system} = rec {
        wlo-classification = python-app;
        docker = docker-img;
        default = wlo-classification;
      };
      # the development environment
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          # the development installation of python
          python-devel
          # non-python packages
          pkgs.nodePackages.pyright
          # for automatically generating nix expressions, e.g. from PyPi
          pkgs.nix-template
          # nix lsp
          pkgs.rnix-lsp
        ];
      };
    };
}
