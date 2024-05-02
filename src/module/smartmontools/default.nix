{ pkgs, ... }:

# TODO: collectd + postgre + timescaledb + prometheus + graphana stack
# TODO: netdata?
# TODO: check out tuptime?
# TODO: https://github.com/tremor-rs/tremor-runtime - rust based stream processor

{
  system = {
    services.smartd.enable = true;

    environment.systemPackages = [
      pkgs.kdiskmark
    ];
  };
}
