{
  programs.gpu-screen-recorder.enable = true;

  home-manager.users.star = {
    programs = {
      ghostty.enable = true;
      vscode.enable = true;
      opencode.enable = true;
      mpv.enable = true;
      claude-code.enable = true;
      codex.enable = true;
      discord.enable = true;
      zellij.enable = true;
    };

    package = {
      nvtop = true;
      obsidian = true;
      github-desktop = true;
      google-chrome = true;
      microsoft-edge = true;
      telegram-desktop = true;
      ffmpeg-full = true;
      losslesscut = true;
      antigravity-ide = true;
      remmina = true;
    };
  };
}
