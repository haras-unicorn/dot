{ inputs, ... }:

{
  machines.nixosModules.wsl =
    {
      config,
      lib,
      ...
    }:
    {
      imports = [ inputs.nixos-wsl.nixosModules.default ];

      config = lib.mkIf (config.dot.hardware.deviceType == "wsl") {
        wsl.enable = true;
        wsl.defaultUser = config.dot.user.user;
        wsl.wslConf.network.hostname = config.networking.hostName;

        # NOTE: WSL provides its own kernel, init, mounts and swap.
        # There is no bootloader, no /boot and no labeled disks.
        boot.loader.grub.enable = lib.mkForce false;
        fileSystems = lib.mkForce { };
        swapDevices = lib.mkForce [ ];

        # NOTE: interface, DNS, firewall and time are managed by Windows/WSL.
        networking.networkmanager.enable = lib.mkForce false;
        networking.nameservers = lib.mkForce [ ];
        networking.firewall.enable = lib.mkForce false;
        services.coredns.enable = lib.mkForce false;
        services.chrony.enable = lib.mkForce false;

        # NOTE: binfmt without WSL interop re-registration breaks .exe launching.
        boot.binfmt.emulatedSystems = lib.mkForce [ ];
        wsl.interop.register = true;

        # NOTE: no KVM/libvirt in WSL.
        virtualisation.libvirtd.enable = lib.mkForce false;
        programs.virt-manager.enable = lib.mkForce false;

        # NOTE: headless CLI only, no desktop or sound stack.
        dot.hardware.graphics = lib.mkForce false;
        dot.hardware.sound = lib.mkForce false;
        dot.hardware.wayland = lib.mkForce false;
        dot.hardware.gaming = lib.mkForce false;
        dot.hardware.browser = lib.mkForce false;
        dot.hardware.visual = lib.mkForce false;
        dot.hardware.multimedia = lib.mkForce false;
        dot.wallpaper.static = true;
        dot.hardware.temperature = lib.mkDefault "/sys/class/thermal/thermal_zone0/temp";
        dot.hardware.display = lib.mkDefault "";

        # NOTE: gc does not work well with WSL
        dot.nix.gc = false;
      };
    };
}
