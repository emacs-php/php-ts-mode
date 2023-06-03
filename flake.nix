{
  nixConfig = {
    extra-substituters = [
      "https://emacs-ci.cachix.org"
    ];
    extra-trusted-public-keys = [
      "emacs-ci.cachix.org-1:B5FVOrxhXXrOL0S+tQ7USrhjMT5iOPH+QN9q0NItom4="
    ];
  };

  inputs.emacs-ci = {
    url = "github:purcell/nix-emacs-ci";
    flake = false;
  };

  outputs = {
    emacs-ci,
    flake-utils,
    ...
  }: let
  in
    flake-utils.lib.eachDefaultSystem
    (system: let
      pkgs =
        import ((import (emacs-ci + "/nix/sources.nix") {
            inherit system;
          })
          .nixpkgs)
        {
          inherit system;
          overlays = [
            (import (emacs-ci + "/overlay.nix"))
          ];
        };

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
      devShells.emacs-snapshot = makeEmacsShell pkgs.emacs-snapshot;
      devShells.emacs-release-snapshot = makeEmacsShell pkgs.emacs-release-snapshot;
    });
}
