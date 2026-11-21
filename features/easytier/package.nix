{
  lib,
  stdenvNoCC,
  fetchzip,
}:
let
  hashes = {
    x86_64-linux = "sha256-ts3zIgGHFxa+p+2RGSHnd1QECLadXMvUmySlnfr1hx4=";
    aarch64-linux = "sha256-DhK8WKsQwZEQrQgM95sp5H+eyePgJ6TVJCyP/4BQLrU=";
  };
in
stdenvNoCC.mkDerivation {
  pname = "easytier-bin";
  version = "2.7.1";

  src = fetchzip {
    url = "https://github.com/EasyTier/EasyTier/releases/download/v2.7.1/easytier-linux-${stdenvNoCC.hostPlatform.parsed.cpu.name}-v2.7.1.zip";
    hash = hashes.${stdenvNoCC.hostPlatform.system};
  };

  dontConfigure = true;
  dontBuild = true;
  # Keep the upstream static, UPX-packed executables unchanged.
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 -t "$out/bin" easytier-core easytier-cli easytier-web easytier-web-embed
    runHook postInstall
  '';

  meta = {
    description = "Decentralized mesh VPN, using official prebuilt binaries";
    homepage = "https://github.com/EasyTier/EasyTier";
    license = lib.licenses.lgpl3Only;
    mainProgram = "easytier-core";
    platforms = builtins.attrNames hashes;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
