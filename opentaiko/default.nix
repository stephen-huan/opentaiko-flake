{ lib
, buildDotnetModule
, dotnetCorePackages
, fetchFromGitHub
, libx11
, libxext
, alsa-lib
}:

buildDotnetModule rec {
  pname = "opentaiko";
  version = "0.6.0.109";

  src = fetchFromGitHub {
    owner = "0auBSQ";
    repo = "OpenTaiko";
    tag = version;
    hash = "sha256-uaGuq1hDb6dzNZ+3OBtYpxTU9nmGGphLQ7RBQDRjhI4=";
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
    libx11
    libxext
    alsa-lib
  ];

  selfContainedBuild = true;

  preFixup = ''
    local -r dotnetInstallPath="''${dotnetInstallPath-$out/lib/$pname}"
    cp $dotnetInstallPath/Libs/$runtimeId/* -t $dotnetInstallPath
  '';

  meta = {
    description = "Free, open source and customizable Taiko-style rhythm game";
    homepage = "https://opentaiko.github.io/";
    changelog = "https://github.com/0auBSQ/OpenTaiko/blob/main/CHANGELOG.md";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ stephen-huan ];
    mainProgram = "OpenTaiko";
  };
}
