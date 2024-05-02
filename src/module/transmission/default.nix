{ ... }:

# FIXME: per user?

{
  system = {
    services.transmission.enable = true;
    services.transmission.openPeerPorts = true;
  };
}
