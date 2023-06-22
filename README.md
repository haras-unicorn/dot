# NixOS dotfiles

Configurations for my NixOS systems.

## Install

```bash
curl -s 'https://gitlab.com/Hrle/dotfiles-nixos/-/raw/{revision(main)}/scripts/install.sh' | \
  sudo bash -s '{device(/dev/sda)}' '{host(virtualbox)}'
```

## Updating

```sh
nixos-rebuild {switch/boot} --flake '/opt/dotfiles#{host(virtualbox)}'
```

## Virtualisation

To enable virtio with Nvidia GPU add the following xml to your VM config in virt-manager:

```xml
<video>
  <model type="virtio" heads="1" primary="yes">
    <acceleration accel3d="yes"/>
  </model>
  <address type="pci" domain="0x0000" bus="0x00" slot="0x01" function="0x0"/>
</video>
<graphics type="spice" autoport="yes">
  <listen type="address"/>
</graphics>
<graphics type="egl-headless">
  <gl rendernode="/dev/nvidia0"/>
</graphics>
```
