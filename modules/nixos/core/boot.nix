{
  lib,
  inputs,
  ...
}:

let
  inherit (inputs) self;

  rawTime = self.lastModifiedDate;
  toInt = lib.toIntBase10;
  pad2 = n: if n < 10 then "0${toString n}" else toString n;
  mod = base: int: base - int * (builtins.div base int);

  isLeap = year: mod year 400 == 0 || (mod year 4 == 0 && mod year 100 != 0);

  daysInMonth =
    year: month:
    if
      lib.elem month [
        1
        3
        5
        7
        8
        10
        12
      ]
    then
      31
    else if
      lib.elem month [
        4
        6
        9
        11
      ]
    then
      30
    else if isLeap year then
      29
    else
      28;

  utcYear = toInt (builtins.substring 0 4 rawTime);
  utcMonth = toInt (builtins.substring 4 2 rawTime);
  utcDay = toInt (builtins.substring 6 2 rawTime);
  utcHour = toInt (builtins.substring 8 2 rawTime);

  hourTotal = utcHour + 8;
  localHour = mod hourTotal 24;
  dayCarry = builtins.div hourTotal 24;
  localDay0 = utcDay + dayCarry;
  monthDays = daysInMonth utcYear utcMonth;

  localDate =
    if localDay0 <= monthDays then
      {
        year = utcYear;
        month = utcMonth;
        day = localDay0;
      }
    else if utcMonth == 12 then
      {
        year = utcYear + 1;
        month = 1;
        day = 1;
      }
    else
      {
        year = utcYear;
        month = utcMonth + 1;
        day = 1;
      };

  dateStr = "${toString localDate.year}${pad2 localDate.month}${pad2 localDate.day}";
  timeStr = "${pad2 localHour}${builtins.substring 10 4 rawTime}";

  suffix = if (self ? rev) then self.shortRev else "dirty";
in
{
  system.nixos.label = "${dateStr}.${timeStr}.${suffix}";
  system.configurationRevision = if (self ? rev) then self.rev else null;

  boot = {
    loader = {
      efi.efiSysMountPoint = lib.mkDefault "/boot";
      systemd-boot = {
        enable = lib.mkDefault true;
        configurationLimit = lib.mkDefault 20;
        consoleMode = lib.mkDefault "auto";
      };
      # efi.canTouchEfiVariables = true;
      timeout = lib.mkDefault 2;
    };
  };
}
