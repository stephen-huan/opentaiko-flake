{ lib
, buildDotnetModule
, dotnetCorePackages
, fetchFromGitHub
, xorg
, alsa-lib
}:

buildDotnetModule rec {
  pname = "opentaiko";
  version = "0.6.0.89";

  src = fetchFromGitHub {
    owner = "0auBSQ";
    repo = "OpenTaiko";
    tag = version;
    hash = "sha256-BJ0JbZ/t5IhHj29OWzYcGtt+qV9Vy7pG9f25g3y3YjE=";
  };

  patches = [
    ./0001-Remove-copy.patch
  ];

  projectFile = "OpenTaiko/OpenTaiko.csproj";
  nugetDeps = ./deps.json;

  buildInputs = [ ];

  dotnet-sdk = dotnetCorePackages.sdk_8_0;
  dotnet-runtime = dotnetCorePackages.runtime_8_0;

  executables = [ "OpenTaiko" ];

  packNupkg = false;

  runtimeDeps = [
    xorg.libX11
    xorg.libXext
    alsa-lib
  ];

  selfContainedBuild = true;

  # buildType = "Debug";

  preFixup = ''
    local -r dotnetInstallPath="''${dotnetInstallPath-$out/lib/$pname}"
    cp $dotnetInstallPath/Libs/$runtimeId/* -t $dotnetInstallPath
  '';

  meta = {
    description = "Free, open source and customizable Taiko-style rhythm game";
    homepage = "https://opentaiko.github.io/";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ stephen-huan ];
    mainProgram = "OpenTaiko";
  };
}
