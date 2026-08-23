{
  config,
  ...
}:
{

  # Having the source path is not the same as having it on the medium.
  isoImage.storeContents = [ config.my.installer.source ];
}
