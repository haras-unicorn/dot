{ self, ... }:

{
  imports = [
    "${self}/src/module/system/sudo/sudo.nix"

    "${self}/src/module/system/grub/grub.nix"
    "${self}/src/module/system/plymouth/plymouth.nix"

    "${self}/src/module/system/rt/rt.nix"

    "${self}/src/module/system/location/location.nix"
    "${self}/src/module/system/network/network.nix"

    "${self}/src/module/system/ssh/ssh.nix"
    "${self}/src/module/system/keyring/keyring.nix"
    "${self}/src/module/system/polkit/polkit.nix"

    "${self}/src/module/system/pipewire/pipewire.nix"

    "${self}/src/module/system/fonts/fonts.nix"
    # "${self}/src/module/system/xserver/xserver.nix"
    "${self}/src/module/system/wayland/wayland.nix"

    "${self}/src/module/system/virtual/virtual.nix"
    "${self}/src/module/system/windows/windows.nix"
  ];

  # TODO: per user?
  # services.transmission.enable = true;
  # services.transmission.openPeerPorts = true;
}
