# NixOS dotfiles

Configurations for my NixOS systems.

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
