# NixOS dotfiles

Configurations for my NixOS systems.

## Install on VPS

Add your SSH keys on online console:

```sh
mkdir -p ~/.ssh
curl -s https://github.com/<user>.keys >> ~/.ssh/authorized_keys
```

Copy secrets via scp. On the local machine:

```sh
scp <path> nixos@<domain>:~/secrets.age
```

Login via SSH. Once logged in, partition, install:

```sh
curl -s https://gitlab.com/<username>/<repo>/-/raw/main/scripts/part | sudo bash -s <device> ~/secrets.age
sudo nixos-install --flake gitlab:<username>/<repo>#<host>-<system>
```

## Virtualisation

### NVIDIA Virtio

To enable virtio with Nvidia GPU add:

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

### Secure boot

To enable secure boot add this to the `os` section:

```xml
<loader readonly="yes" secure="yes" type="pflash">/etc/ovmf/edk2-x86_64-secure-code.fd</loader>
<nvram template="/etc/ovmf/edk2-i386-vars.fd"/>
```

, and this to the `features` section:

```xml
<smm state="on"/>
```
