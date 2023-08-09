{
  description = "A Python package defined as a Nix Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    {
      # define an overlay to add wlo-classification to nixpkgs
      overlays.default = (final: prev: {
        inherit (self.packages.${final.system}) wlo-classification;
      });
    } //
    flake-utils.lib.eachDefaultSystem (system:
      let
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
                         fastapi
                         pydantic
                         uvicorn
                         transformers
                         keras
                        ];

        ### create the python installation for development
        # the development installation contains all build packages,
        # plus some additional ones we do not need to include in production.
        python-packages-devel = py-pkgs:
          with py-pkgs; [ipython
                         jupyter
                         black
                        ] ++ (python-packages-build py-pkgs);

        ### create the python package
        # fetch an external resource for NLTK
        nltk-stopwords = pkgs.fetchzip {
          url = "https://github.com/nltk/nltk_data/raw/5db857e6f7df11eabb5e5665836db9ec8df07e28/packages/corpora/stopwords.zip";
          sha256 = "sha256-tX1CMxSvFjr0nnLxbbycaX/IBnzHFxljMZceX5zElPY=";
        };

        # download the metadata on the bert language model being used
        gbert-base = pkgs.fetchgit {
          url = "https://huggingface.co/deepset/gbert-base";
          rev = "e2073f52ebb8dd8b50ed5230a9752e251105c096";
          hash = "sha256-iRNhzt/VNkOErS1/slIQ0jS0472qNSlNNow9juzdu3w=";
          # do not fetch the files managed by git LFS
          fetchLFS = false;
        };

        # download the full wlo-classification model
        wlo-classification-model = pkgs.fetchFromGitLab {
          domain = "gitlab.gwdg.de";
          owner = "jopitz";
          repo = "wlo-classification-model";
          rev = "66661ad257969a66af632fc5b184765d0ef95fd8";
          hash = "sha256-CIZAbCH5JUAXOchxSByCxUO/p9jR1B+8CkIOoNOQtiA=";
        };
        
        # build the application itself
        python-app = python.pkgs.buildPythonApplication {
          pname = "wlo-classification";
          version = "0.1.0";
          src = projectDir;
          propagatedBuildInputs = (python-packages-build python.pkgs);
          # no tests are available, nix built-in import check fails
          # due to how we handle import of nltk-stopwords
          doCheck = false;
          # put nltk-stopwords into a directory
          preBuild = ''
            ${pkgs.coreutils}/bin/mkdir -p \
              $out/lib/nltk_data/corpora/stopwords

            ${pkgs.coreutils}/bin/cp -r \
              ${nltk-stopwords}/* \
              $out/lib/nltk_data/corpora/stopwords
          '';
          # make the created folder discoverable for NLTK
          makeWrapperArgs = ["--set NLTK_DATA $out/lib/nltk_data"];
          # replace cli argument with local file
          prePatch = ''
            substituteInPlace src/webservice.py \
              --replace "args.model" "\"${wlo-classification-model}\"" \
              --replace "parser.add_argument(\"model\")" ""
  
            substituteInPlace src/*.py \
              --replace "deepset/gbert-base" "${gbert-base}"
        '';
        };
        
        ### build the docker image
        docker-img = pkgs.dockerTools.buildLayeredImage {
          name = python-app.pname;
          tag = python-app.version;
          config = {
            Cmd = [ "${python-app}/bin/wlo-classification" ];
          };
        };

      in rec {
        # the packages that we can build
        packages = rec {
          wlo-classification = python-app;
          docker = docker-img;
          default = wlo-classification;
        };
        # the development environment
        devShells.default = pkgs.mkShell {
          buildInputs = [
            # the development installation of python
            (python.withPackages python-packages-devel)
            # non-python packages
            pkgs.nodePackages.pyright
            # for automatically generating nix expressions, e.g. from PyPi
            pkgs.nix-init
            pkgs.nix-template
          ];
        };
      });
}
