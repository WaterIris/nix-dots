{ ... }:
{
  services.logind.settings.Login.HandleLidSwitch = "ignore";
  services.tlp = {
    enable = true;
    settings = {
      START_CHARGE_THRESH_BAT0 = 0; # Dummy value
      STOP_CHARGE_THRESH_BAT0 = 1; # Actualy enables conservation mode
    };
  };
  services.udisks2.enable = true;
  services.gvfs.enable = true;
}
