{
  pkgs,
  config,
  lib,
  ...
}:

let
  user = config.dot.host.user;

  qemuPackage = pkgs.qemu_kvm;
  hasMinCpu = config.dot.hardware.threads >= 8;
  hasMinMem = config.dot.hardware.memory / 1000 / 1000 / 1000 >= 16;

  win11 = pkgs.writeShellApplication {
    name = "win11";
    runtimeInputs = [
      pkgs.quickemu
      pkgs.coreutils
    ];
    text = ''
      mkdir -p "${config.xdg.dataHome}/win11"
      cd "${config.xdg.dataHome}/win11"
      if [ ! -f windows-11.conf ]; then
        quickget windows 11
        # NOTE: https://github.com/quickemu-project/quickemu/issues/1475#issuecomment-2639232863
        sed -i 's|^fixed_iso="windows-11/virtio-win\.iso"|#&|' windows-11.conf
      cat << EOF >> windows-11.conf
      extra_args=" \
        -drive media=cdrom,index=3,file=windows-11/virtio-win.iso \
      "
      EOF
        # NOTE: first time install virtio then switch to virtio keyboar/mouse
        exec quickemu \
          --vm windows-11.conf \
          --fullscreen \
          "$@"
      else
        exec quickemu \
          --vm windows-11.conf \
          --fullscreen \
          --mouse virtio \
          --keyboard virtio \
          "$@"
      fi
    '';
  };
in
{
  nixosModule = lib.mkIf (hasMinCpu && hasMinMem) {
    virtualisation.libvirtd = {
      enable = true;
      qemu = {
        package = qemuPackage;
        swtpm.enable = true;
      };
    };

    users.users.${user}.extraGroups = [
      "libvirtd"
      "kvm"
      "input"
    ];

    programs.virt-manager.enable = true;
  };

  homeManagerModule = lib.mkIf (hasMinCpu && hasMinMem) {
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
