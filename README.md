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

## Known issues

### Transmission folders

This errors into "failed to setup mount namespacing".

```nix
services.transmission.settings.download-dir = "${config.services.transmission.home}/downloads";
services.transmission.settings.incomplete-dir = "${config.services.transmission.home}/.incomplete";
services.transmission.settings.watch-dir = "${config.services.transmission.home}/torrents";
services.transmission.settings.watch-dir-enabled = true;
````

### Compartmentalization

I should have a modules folder for packages with a lot of configurations or groups of packages since my `home.nix` is getting crowded and hard to navigate.

