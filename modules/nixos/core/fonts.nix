# Update font cache after changing this module:
# fc-cache -fv

{ lib, pkgs, ... }:
{
  fonts = {
    enableDefaultPackages = lib.mkDefault true;
    fontDir.enable = true;

    packages = with pkgs.unstable; [
      # Primary Unicode families.
      noto-fonts
      noto-fonts-lgc-plus
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
      noto-fonts-monochrome-emoji
      unifont
      unifont_upper
      freefont_ttf
      symbola

      # Web and office compatibility.
      liberation_ttf
      dejavu_fonts
      corefonts
      vista-fonts

      # Modern UI families.
      inter
      pretendard
      geist-font
      source-sans
      roboto
      cantarell-fonts
      atkinson-hyperlegible
      ubuntu-classic
      ibm-plex

      # CJK families.
      source-han-sans
      source-han-serif
      wqy_microhei
      wqy_zenhei
      sarasa-gothic
      lxgw-wenkai

      # Serif, book, and math-heavy documents.
      source-serif
      stix-two
      libertinus
      gyre-fonts
      charis
      gentium

      # Monospace and programming families.
      maple-mono."NF-CN"
      jetbrains-mono
      monaspace
      iosevka
      lilex
      aporetic
      cascadia-code
      commit-mono
      recursive
      victor-mono
      source-code-pro
      fira-code
      fira-code-symbols
      nerd-fonts.jetbrains-mono
      nerd-fonts.monaspace
      nerd-fonts.fira-code
      nerd-fonts.hack
      nerd-fonts.iosevka-term
      nerd-fonts.caskaydia-cove

      # Emoji fallbacks.
      twemoji-color-font
      openmoji-color

      # Symbols and icon families.
      font-awesome
      material-icons
      material-design-icons
      powerline-fonts
      nerd-fonts.symbols-only
    ];

    fontconfig = {
      enable = true;
      antialias = true;

      hinting = {
        enable = true;
        style = "slight";
      };

      subpixel = {
        rgba = "rgb";
        lcdfilter = "default";
      };

      defaultFonts = {
        serif = [
          "Source Serif"
          "Noto Serif"
          "Source Han Serif SC"
          "Noto Serif CJK SC"
          "STIX Two Text"
          "Libertinus Serif"
          "TeX Gyre Termes"
          "Times New Roman"
          "DejaVu Serif"
          "FreeSerif"
          "Symbola"
          "Unifont"
          "Noto Color Emoji"
          "Twemoji"
          "OpenMoji Color"
          "Symbols Nerd Font"
        ];

        sansSerif = [
          "Inter"
          "Pretendard"
          "Geist"
          "Source Sans 3"
          "Source Sans"
          "Noto Sans"
          "Source Han Sans SC"
          "Noto Sans CJK SC"
          "Arial"
          "Segoe UI"
          "Roboto"
          "Atkinson Hyperlegible"
          "IBM Plex Sans"
          "DejaVu Sans"
          "WenQuanYi Micro Hei"
          "Symbola"
          "Unifont"
          "Noto Color Emoji"
          "Twemoji"
          "OpenMoji Color"
          "Symbols Nerd Font"
        ];

        monospace = [
          "Maple Mono NF CN"
          "Maple Mono"
          "JetBrainsMono Nerd Font"
          "JetBrains Mono"
          "Monaspace Neon"
          "Iosevka"
          "Lilex"
          "Aporetic Sans Mono"
          "Cascadia Code"
          "CommitMono"
          "FiraCode Nerd Font"
          "Fira Code"
          "IosevkaTerm Nerd Font"
          "Hack Nerd Font"
          "Sarasa Mono SC"
          "Noto Sans Mono CJK SC"
          "Source Code Pro"
          "DejaVu Sans Mono"
          "Symbola"
          "Unifont"
          "Noto Color Emoji"
          "Twemoji"
          "OpenMoji Color"
          "Symbols Nerd Font"
        ];

        emoji = [
          "Noto Color Emoji"
          "Twemoji"
          "OpenMoji Color"
          "Noto Emoji"
          "Symbols Nerd Font"
        ];
      };
    };
  };
}
