{ modulesPath, ... }:
{
  # Official NixOS GNOME + Calamares installation medium. Which upstream medium
  # a given installer is based on is the one thing that cannot be an option:
  # module imports may not depend on configuration.
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-graphical-calamares-gnome.nix")
  ];

  my.installer = {
    target = "installer";
  };

  # SquashFS compression examples. Keep all of them commented to use the
  # upstream NixOS default; uncomment exactly one option when needed.

  # Fast ISO builds with a good decompression speed, useful during development.
  # This trades a noticeably larger ISO for shorter iteration times.
  # isoImage.squashfsCompression = "zstd -Xcompression-level 1";

  # Balanced compression ratio and speed, suitable for normal release images.
  # This is also the compression setting currently used by upstream NixOS.
  # isoImage.squashfsCompression = "zstd -Xcompression-level 19";

  # The smallest practical Zstandard image, suitable when retaining Zstd's fast
  # decompression matters more than ISO build time.
  # isoImage.squashfsCompression = "zstd -Xcompression-level 22";

  # Usually produces the smallest bootable x86_64 ISO, suitable when image size
  # is the priority and slow compression and decompression are acceptable.
  # isoImage.squashfsCompression = "xz -Xdict-size 100% -Xbcj x86";

  # Widely compatible but generally worse than Zstd in both ratio and speed;
  # useful mainly for comparing against older SquashFS tooling.
  # isoImage.squashfsCompression = "gzip -Xcompression-level 9";

  # Very fast decompression with a modest compression ratio, suitable for media
  # where read speed and CPU usage matter more than ISO size.
  # isoImage.squashfsCompression = "lz4 -Xhc";

  # A legacy middle ground between gzip and LZ4, useful only when compatibility
  # with an environment already standardized on LZO is required.
  # isoImage.squashfsCompression = "lzo -Xalgorithm lzo1x_999 -Xcompression-level 9";

  # No compression: useful only for debugging or measuring raw image contents;
  # it creates a very large ISO but minimizes compression/decompression work.
  # isoImage.squashfsCompression = null;

  # Deprecated and unsupported by the Linux SquashFS kernel driver. Listed only
  # for completeness; enabling it would make the live ISO unbootable.
  # isoImage.squashfsCompression = "lzma";
}
