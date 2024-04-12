{
  mkShell,
  python3,
  pyright,
  nix-init,
  nix-template,
  nix-tree
}:
mkShell {
  packages = [
    (python3.withPackages (
      py-pkgs:
      with py-pkgs;
      [
        isort
        ipython
        jupyter
        black
        mypy
      ]
      ++ py-pkgs.wlo-classification.propagatedBuildInputs
    ))
    pyright
    nix-init
    nix-template
    nix-tree
  ];
}
