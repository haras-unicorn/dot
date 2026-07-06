{
  machines.nixosModules.qemu-libvirt-quickemu =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    lib.mkIf (config.dot.hardware.threads >= 8 && config.dot.hardware.memory / 1000 / 1000 / 1000 >= 16)
      {
        virtualisation.libvirtd = {
          enable = true;
          qemu = {
            package = pkgs.qemu_kvm;
            swtpm.enable = true;
          };
        };

        users.users.${config.dot.user.user}.extraGroups = [
          "libvirtd"
          "kvm"
          "input"
        ];

        programs.virt-manager.enable = true;
      };
}
