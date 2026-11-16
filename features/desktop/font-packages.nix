{ pkgs }:
with pkgs.unstable;
[
  # Preferred families and broad script coverage.
  inter
  noto-fonts
  noto-fonts-cjk-sans
  noto-fonts-cjk-serif
  noto-fonts-color-emoji
  nerd-fonts.jetbrains-mono

  # Unicode, legacy family names, and monochrome glyphs.
  unifont
  unifont_upper
  freefont_ttf
  symbola
  noto-fonts-monochrome-emoji

  # Web and Office document compatibility.
  corefonts
  vista-fonts
  vista-fonts-chs
  vista-fonts-cht
  liberation_ttf
  dejavu_fonts
  roboto
  open-sans
  source-sans
  lato
  montserrat
  poppins
  cantarell-fonts
  ubuntu-classic
  pretendard

  # Named CJK, publishing, linguistic, and mathematical families.
  source-han-sans
  source-han-serif
  wqy_microhei
  wqy_zenhei
  source-serif
  stix-two
  libertinus
  gyre-fonts
  charis
  gentium

  # Code and icon fonts.
  jetbrains-mono
  cascadia-code
  source-code-pro
  fira-code
  font-awesome
  material-icons
  material-design-icons
  powerline-fonts
  nerd-fonts.symbols-only
]
