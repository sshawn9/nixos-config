{ self, ... }:
{
  _class = "homeManager";
  imports = [
    self.homeModules.package
    self.homeModules.fileSources
  ];
}
