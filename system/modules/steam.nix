{ ... }:
{
    programs.steam = {
        enable = true;
        remotePlay.openFirewall = false; # Open ports for Steam Remote Play
            dedicatedServer.openFirewall = false; # Open ports for Source dedicated server
            localNetworkGameTransfers.openFirewall = false; # Open ports for local network game transfers
    };

}
