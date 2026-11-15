{ self, ... }:
{
  imports = [
    self.homeModules.fileSources
    self.homeModules.package
    ./home-manager/ai/claude-code.nix
    ./home-manager/ai/codex.nix
    ./home-manager/ai/opencode.nix
    ./home-manager/desktop/applications.nix
    ./home-manager/desktop/applications-linux.nix
    ./home-manager/desktop/discord.nix
    ./home-manager/desktop/input-linux.nix
    ./home-manager/desktop/mousehop.nix
    ./home-manager/development/environment.nix
    ./home-manager/development/just.nix
    ./home-manager/development/packages.nix
    ./home-manager/development/packages-linux.nix
    ./home-manager/editors/editors.nix
    ./home-manager/media/haruna.nix
    ./home-manager/media/mpv.nix
    ./home-manager/media/packages.nix
    ./home-manager/nix/tools.nix
  ];
}
