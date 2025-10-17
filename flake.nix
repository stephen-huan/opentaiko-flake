{
  description = "Flake for OpenTaiko";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;
      systems = lib.systems.flakeExposed;
      eachDefaultSystem = f: builtins.foldl' lib.attrsets.recursiveUpdate { }
        (map f systems);
    in
    eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        formatter = pkgs.nixpkgs-fmt;
        linters = [ pkgs.statix ];
      in
      {
        packages.${system} = {
          opentaiko-hub = pkgs.callPackage ./opentaiko-hub { };
        };

        formatter.${system} = formatter;

        checks.${system}.lint = pkgs.stdenvNoCC.mkDerivation {
          name = "lint";
          src = ./.;
          doCheck = true;
          nativeCheckInputs = linters ++ lib.singleton formatter;
          checkPhase = ''
            nixpkgs-fmt --check .
            statix check
          '';
          installPhase = "touch $out";
        };

        apps.${system} = {
          update = {
            type = "app";
            program = lib.getExe (pkgs.writeShellApplication {
              name = "update";
              runtimeInputs = [ pkgs.nix-update ];
              text = lib.concatMapStringsSep "\n"
                (package: "nix-update --flake ${package} || true")
                (builtins.attrNames self.packages.${system});
            });
          };
        };

        devShells.${system}.default = (pkgs.mkShellNoCC.override {
          stdenv = pkgs.stdenvNoCC.override {
            initialPath = [ pkgs.coreutils ];
          };
        }) {
          packages = with self.packages.${system}; [
            opentaiko-hub
          ];
        };
      }
    );
}
