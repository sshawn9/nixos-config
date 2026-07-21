# Update font cache after changing this module:
# fc-cache -fv

{
  lib,
  pkgs,
  config,
  ...
}:

let
  fullFontPackages = with pkgs.unstable; [
    # Preferred families and broad script coverage.
    inter # Preferred Latin sans-serif for desktop and web UI.
    noto-fonts # Noto Sans/Serif and fonts for most non-CJK writing systems.
    noto-fonts-cjk-sans # CJK sans-serif plus Noto Sans Mono CJK.
    noto-fonts-cjk-serif # CJK serif for documents requesting serif text.
    noto-fonts-color-emoji # Preferred full-color Unicode emoji.
    nerd-fonts.jetbrains-mono # Preferred monospace with terminal and editor icons.

    # Last-resort Unicode and legacy family coverage.
    unifont # Broad Basic Multilingual Plane fallback.
    unifont_upper # Rare characters in supplementary Unicode planes.
    freefont_ttf # GNU FreeSans/FreeSerif/FreeMono names used by older documents.
    symbola # Legacy symbol, dingbat, and historic-script coverage.
    noto-fonts-monochrome-emoji # Outline emoji for printing and monochrome renderers.

    # Microsoft web and Office document compatibility.
    corefonts # Arial, Times New Roman, Verdana, Georgia, Tahoma, and related fonts.
    vista-fonts # Calibri, Cambria, Candara, Consolas, Constantia, and Corbel.
    vista-fonts-chs # Microsoft YaHei for Simplified Chinese documents.
    vista-fonts-cht # Microsoft JhengHei for Traditional Chinese documents.
    liberation_ttf # Metric-compatible substitutes for Arial, Times New Roman, and Courier New.
    dejavu_fonts # Common Linux document and web font family names.

    # Common web, application UI, and presentation families.
    roboto # Android/Material UI and one of the most common web fonts.
    open-sans # Common web body-text and presentation family.
    source-sans # Adobe Source Sans 3 for web and document compatibility.
    lato # Common web, presentation, and office-document family.
    montserrat # Common web heading and presentation family.
    poppins # Common geometric sans-serif used by websites and slides.
    cantarell-fonts # GNOME application and Linux desktop compatibility.
    ubuntu-classic # Ubuntu desktop and document family name compatibility.
    pretendard # Modern Korean UI and document family.

    # Named CJK families used by Chinese documents and older Linux software.
    source-han-sans # Adobe family name for the same design ecosystem as Noto CJK Sans.
    source-han-serif # Adobe family name for the same design ecosystem as Noto CJK Serif.
    wqy_microhei # Legacy compact Chinese sans-serif used by Linux applications.
    wqy_zenhei # Legacy CJK sans-serif with broad character coverage.

    # Publishing, academic, linguistic, and mathematical documents.
    source-serif # Adobe Source Serif 4 family.
    stix-two # Scientific text, mathematical symbols, and OpenType math.
    libertinus # Book typography and TeX/OpenType math compatibility.
    gyre-fonts # OpenType replacements for the standard PostScript font families.
    charis # Linguistics, IPA, and highly readable long-form text.
    gentium # Multilingual Latin, Greek, Cyrillic, and linguistic notation.

    # Exact family names commonly requested by code editors and code samples.
    jetbrains-mono # Unpatched JetBrains Mono for documents requesting its original name.
    cascadia-code # Microsoft coding font and Windows Terminal compatibility.
    source-code-pro # Adobe coding font commonly used by editors and websites.
    fira-code # Popular programming font with coding ligatures.

    # Icon families referenced directly by desktop applications and terminal themes.
    font-awesome # Widely used general-purpose web and application icons.
    material-icons # Google's original Material icon family.
    material-design-icons # Community Material Design icon expansion.
    powerline-fonts # Legacy Powerline-patched fonts and symbols.
    nerd-fonts.symbols-only # Standalone Nerd Font icons for font fallback.
  ];
in
{
  fonts = {
    enableDefaultPackages = lib.mkDefault config.my.shared.desktops.active != [ ];
    fontDir.enable = lib.mkDefault true;

    packages = lib.optionals (config.my.shared.desktops.active != [ ]) fullFontPackages;

    fontconfig = {
      enable = lib.mkDefault true;
      antialias = true;

      hinting = {
        enable = lib.mkDefault true;
        style = "slight";
      };

      subpixel = {
        rgba = "rgb";
        lcdfilter = "default";
      };

      defaultFonts = {
        serif = [
          "Noto Serif"
          "Noto Serif CJK SC"
        ];

        sansSerif = [
          "Inter"
          "Noto Sans CJK SC"
          "Noto Sans"
        ];

        monospace = [
          "JetBrainsMono Nerd Font Mono"
          "Noto Sans Mono CJK SC"
        ];

        emoji = [
          "Noto Color Emoji"
        ];
      };
    };
  };
}
