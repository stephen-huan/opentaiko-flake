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
        inherit (self.packages.${system}) opentaiko opentaiko-hub;
      in
      {
        packages.${system} = rec {
          default = opentaiko;
          opentaiko-unwrapped = pkgs.callPackage ./opentaiko { };
          opentaiko-hub-unwrapped = pkgs.callPackage ./opentaiko-hub { };
          opentaiko = pkgs.symlinkJoin {
            inherit (opentaiko-unwrapped) name meta;
            paths = [ opentaiko-unwrapped ];
            buildInputs = [ pkgs.makeWrapper ];
            postBuild = ''
              wrapProgram $out/bin/OpenTaiko \
                --suffix XDG_DATA_DIRS : \
                  "/run/opengl-driver/share:/run/opengl-driver-32/share"
            '';
          };
          opentaiko-hub = pkgs.symlinkJoin {
            inherit (opentaiko-hub-unwrapped) name meta;
            paths = [ opentaiko-hub-unwrapped ];
            buildInputs = [ pkgs.makeWrapper ];
            postBuild = ''
              wrapProgram $out/bin/OpenTaiko-Hub \
                --set WEBKIT_DISABLE_DMABUF_RENDERER "1"
            '';
          };
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
            opentaiko
            opentaiko-hub
          ];
        };
      }
    );
}
