{ lib
, stdenv
, rustPlatform
, fetchFromGitHub
, fetchNpmDeps
, cargo-tauri
, glib-networking
, nodejs
, npmHooks
, openssl
, pkg-config
, webkitgtk_4_1
, gst_all_1
, wrapGAppsHook3
, python3
, vips
, pngquant
, optipng
, srcOnly
, makeSetupHook
, jq
, prefetch-npm-deps
, diffutils
}:

let
  # copied from https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/node/build-npm-package/hooks/default.nix
  npmConfigHook = makeSetupHook
    {
      name = "npm-config-hook";
      substitutions = {
        nodeSrc = srcOnly nodejs;
        nodeGyp = "${nodejs}/lib/node_modules/npm/node_modules/node-gyp/bin/node-gyp.js";
        npmArch = stdenv.targetPlatform.node.arch;
        npmPlatform = stdenv.targetPlatform.node.platform;

        # Specify `diff`, `jq`, and `prefetch-npm-deps` by abspath to ensure that the user's build
        # inputs do not cause us to find the wrong binaries.
        diff = "${diffutils}/bin/diff";
        jq = "${jq}/bin/jq";
        prefetchNpmDeps = "${prefetch-npm-deps}/bin/prefetch-npm-deps";

        nodeVersion = nodejs.version;
        nodeVersionMajor = lib.versions.major nodejs.version;

        # replace downloaded binaries
        pngquant = lib.getExe pngquant;
        optipng = lib.getExe optipng;
      };
    } ./npm-config-hook.sh;
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "opentaiko-hub";
  version = "0.1.20";

  src = fetchFromGitHub {
    owner = "OpenTaiko";
    repo = "OpenTaiko-Hub";
    tag = "v${finalAttrs.version}";
    hash = "sha256-tQlf2d8Jyo5Ojku3jn5HSxZN6NdhaAmPBbFUWA+YPmo=";
  };

  cargoHash = "sha256-AwVL5+1ZbmZ/MAwQTQcV/2uVz5LG0Q4VGKm5JxbVqHk=";

  npmDeps = fetchNpmDeps {
    name = "${finalAttrs.pname}-${finalAttrs.version}-npm-deps";
    inherit (finalAttrs) src;
    hash = "sha256-VmlTsszMjEUKfMq5bwtNZAJLa0ST1ZA0zbBxN+Dzv7I=";
  };

  nativeBuildInputs = [
    cargo-tauri.hook

    nodejs
    npmConfigHook

    pkg-config

    python3
    vips
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [ wrapGAppsHook3 ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    glib-networking
    openssl
    webkitgtk_4_1

    gst_all_1.gstreamer
    # https://github.com/OpenTaiko/OpenTaiko-Hub/issues/4#issuecomment-3415356709
    # gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad

    vips
  ];

  cargoRoot = "src-tauri";
  buildAndTestSubdir = finalAttrs.cargoRoot;

  meta = {
    description = "Launcher, updater and asset manager for OpenTaiko";
    homepage = "https://opentaiko.github.io/";
    changelog = "https://github.com/OpenTaiko/OpenTaiko-Hub/blob/main/CHANGELOG.md";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ stephen-huan ];
    mainProgram = "OpenTaiko-Hub";
  };
})
