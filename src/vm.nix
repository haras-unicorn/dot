{
  pkgs,
  config,
  lib,
  ...
}:

# NOTE: https://github.com/quickemu-project/quickemu/issues/1475#issuecomment-2639232863
# NOTE: put this in the windows-11.conf
# #fixed_iso="windows-11/virtio-win.iso" -> YES COMMENT THIS OUT
# extra_args="-drive media=cdrom,index=3,file=windows-11/virtio-win.iso"
# extra_args="-cpu host,+hypervisor,+invtsc,l3-cache=on,migratable=no,hv-relaxed,hv-vapic,hv-spinlocks=0x1fff,hv-time,hv-synic,hv-stimer,hv-tlbflush,hv-ipi,hv-reset,hv-frequencies,hv-vpindex,topoext"

let
  user = config.dot.user;

  qemuPackage = pkgs.qemu_kvm;
  hasMinCpu = config.dot.hardware.threads >= 8;
  hasMinMem = config.dot.hardware.memory / 1000 / 1000 / 1000 >= 16;

  win11 = pkgs.writeShellApplication {
    name = "win11";
    runtimeInputs = [ pkgs.quickemu ];
    text = ''
      mkdir -p "${config.xdg.dataHome}/win11"
      cd "${config.xdg.dataHome}/win11"
      if [ ! -f windows-11.conf ]; then
        quickget windows 11
      fi
      exec quickemu \
        --vm windows-11.conf \
        --fullscreen \
        "$@"
    '';
  };
in
{
  branch.nixosModule.nixosModule = lib.mkIf (hasMinCpu && hasMinMem) {
    virtualisation.libvirtd = {
      enable = true;
      qemu = {
        package = qemuPackage;
        swtpm.enable = true;
        ovmf = {
          enable = true;
          packages = [ pkgs.OVMFFull.fd ];
        };
      };
    };

    users.users.${user}.extraGroups = [
      "libvirtd"
      "kvm"
      "input"
    ];

    programs.dconf.enable = true;

    programs.virt-manager.enable = true;
  };

  branch.homeManagerModule.homeManagerModule = lib.mkIf (hasMinCpu && hasMinMem) {
    home.packages = [
      pkgs.quickemu
      win11
    ];

    xdg.desktopEntries = {
      win11 = {
        name = "Windows 11";
        exec = "${win11}/bin/win11";
        terminal = false;
      };
    };
  };
}
