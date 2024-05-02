{ ... }:

{
  system = {
    services.cachix-agent.enable = true;
    services.cachix-agent.credentialsFile = "/etc/cachix-agent.token";
    services.cachix-agent.host = "https://haras.cachix.org";
  };
}
