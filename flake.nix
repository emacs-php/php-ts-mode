{
  nixConfig = {
    extra-substituters = [
      "https://emacs-ci.cachix.org"
    ];
    extra-trusted-public-keys = [
      "emacs-ci.cachix.org-1:B5FVOrxhXXrOL0S+tQ7USrhjMT5iOPH+QN9q0NItom4="
    ];
  };

  inputs.emacs-ci.url = "github:purcell/nix-emacs-ci";

  outputs = {
    nixpkgs,
    emacs-ci,
    flake-utils,
    ...
  }: let
  in
    flake-utils.lib.eachDefaultSystem
    (system: let
      pkgs = nixpkgs.legacyPackages.${system};

      emacsCIWith = emacs:
        (pkgs.emacs.pkgs.overrideScope'
          (_: _: {
            inherit emacs;
          }))
        .withPackages (epkgs: [
          (epkgs.treesit-grammars.with-grammars (grammars: [grammars.tree-sitter-php]))
        ]);

      makeEmacsShell = emacs:
        pkgs.mkShell {
          buildInputs = [
            (emacsCIWith emacs)
          ];
        };
    in {
      devShells.emacs-snapshot =
        makeEmacsShell emacs-ci.packages.${system}.emacs-snapshot;
      devShells.emacs-release-snapshot =
        makeEmacsShell emacs-ci.packages.${system}.emacs-release-snapshot;
      devShells.emacs-29-1 = makeEmacsShell emacs-ci.packages.${system}.emacs-29-1;
    });
}
