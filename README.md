# opentaiko-flake

Flake packaging [OpenTaiko](https://github.com/0auBSQ/OpenTaiko)
and [OpenTaiko-Hub](https://github.com/OpenTaiko/OpenTaiko-Hub).

The packages `opentaiko` and `opentaiko-hub` are exposed
through `opentaiko.packages.${system}` as well as through
a devshell `devShells.${system}.default`. The unwrapped
versions are available under `*-unwrapped`.

## OpenTaiko-Hub

To run OpenTaiko-Hub, it might be necessary to
set `WEBKIT_DISABLE_DMABUF_RENDERER=1`. See
https://github.com/OpenTaiko/OpenTaiko-Hub/issues/4#issuecomment-3415356709.
This is taken care of in the wrapped version.

```shell
nix run github:stephen-huan/opentaiko-flake#opentaiko-hub
```

There are warnings if the settings folder is not copied to
`$XDG_DOCUMENTS_DIR/settings` (`~/Documents/settings` by default). This can
be done with `nix run github:stephen-huan/opentaiko-flake#copy-settings`.

## OpenTaiko

OpenTaiko must be ran from its folder (`$XDG_DOCUMENTS_DIR/OpenTaiko` by
default), i.e., ran with `./OpenTaiko` in the game directory so it can find
the appropriate assets. In addition, the folder must be mutable as the game
writes state to this directory (so it cannot be the nix store).

The entire game folder can be copied with `nix run
github:stephen-huan/opentaiko-flake#copy-game-full` (or downloaded with
OpenTaiko-Hub). Of course, the downloaded version from OpenTaiko-Hub
or the [GitHub releases](https://github.com/0auBSQ/OpenTaiko/releases)
will not run on NixOS. To replace just the game binary, run `nix run
github:stephen-huan/opentaiko-flake#copy-game`. Now the game can be ran from
either the hub or with `nix run github:stephen-huan/opentaiko-flake#run-game`.

The wrapper fixes the following issue

```
ERR: RendererVk.cpp:196 (VerifyExtensionsPresent): Extension not supported: VK_KHR_surface
ERR: RendererVk.cpp:196 (VerifyExtensionsPresent): Extension not supported: VK_KHR_surface
ERR: RendererVk.cpp:196 (VerifyExtensionsPresent): Extension not supported: VK_KHR_xcb_surface
ERR: RendererVk.cpp:196 (VerifyExtensionsPresent): Extension not supported: VK_KHR_xcb_surface
ERR: Display.cpp:1052 (initialize): ANGLE Display::initialize error 0: Internal Vulkan error (-7): A requested extension is not supported, in ../../third_party/angle/src/libANGLE/renderer/vulkan/RendererVk.cpp, enableInstanceExtensions:1672.
ERR: Display.cpp:1052 (initialize): ANGLE Display::initialize error 0: Internal Vulkan error (-7): A requested extension is not supported, in ../../third_party/angle/src/libANGLE/renderer/vulkan/RendererVk.cpp, enableInstanceExtensions:1672.
```

with a snippet from
[`buildFHSEnv`](https://github.com/NixOS/nixpkgs/blob/3e1cfd923405b8baedf2a36190b02b2939a0a1cc/pkgs/build-support/build-fhsenv-bubblewrap/buildFHSEnv.nix#L100-L101).

```bash
# XDG_DATA_DIRS is used by pressure-vessel (steam proton) and vulkan loaders to find the corresponding icd
export XDG_DATA_DIRS=$XDG_DATA_DIRS${XDG_DATA_DIRS:+:}/run/opengl-driver/share:/run/opengl-driver-32/share
```

### Packaging

To fetch the
[dotnet dependencies](https://nixos.org/manual/nixpkgs/stable/#generating-and-updating-nuget-dependencies)
for OpenTaiko, run

```shell
nix build .#opentaiko.passthru.fetch-deps
./result ./opentaiko/deps.json
```

Note that `/bin/sh` is required; otherwise there is the following error.

```
Processing post-creation actions...
Unable to apply permissions 600 to "nuget.config".
Post action failed.
Manual instructions: Run 'chmod 600 nuget.config'
```

The debug build is helpful to get tracebacks.
