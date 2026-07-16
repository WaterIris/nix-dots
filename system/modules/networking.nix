{ ... }:
{
  networking.hostName = "alduin";
  networking.networkmanager.enable = true; # CHANGE: disable and configure manually / use systemd-networkd if preferred
  networking.firewall.enable = true;
}
