{ lib, ... }:

{
  self.lib.networkIsolate.isolate =
    pkgs:
    {
      interfaces,
      name,
      cidr,
      command,
    }:
    pkgs.writeShellApplication {
      name = "network-isolate-${name}";
      runtimeInputs = with pkgs; [
        iproute2
        iptables
        procps
        sudo
      ];
      text = ''
        NS="${name}"
        VH="veth-${name}"
        VN="veth-${name}-ns"
        SUBNET="${cidr}"
        HOST_IP="$SUBNET.1"
        NS_IP="$SUBNET.2"

        cleanup() {
        ${lib.concatMapStringsSep "\n" (interface: ''
          iptables -t nat -D POSTROUTING -s "$SUBNET.0/24" -o "${interface}" -j MASQUERADE 2>/dev/null || true
          iptables -D FORWARD -i "${interface}" -o "$VH" -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || true
          iptables -D FORWARD -i "$VH" -o "${interface}" -j ACCEPT 2>/dev/null || true
        '') interfaces}

          ip netns del "$NS" 2>/dev/null || true
          ip link del "$VH" 2>/dev/null || true
          rm -rf "/etc/netns/$NS"
        }

        trap cleanup EXIT

        sysctl -w net.ipv4.ip_forward=1 >/dev/null

        ${lib.concatMapStringsSep "\n" (interface: ''
          iptables -t nat -A POSTROUTING -s "$SUBNET.0/24" -o "${interface}" -j MASQUERADE
          iptables -A FORWARD -i "${interface}" -o "$VH" -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
          iptables -A FORWARD -i "$VH" -o "${interface}" -j ACCEPT
        '') interfaces}

        ip netns del "$NS" 2>/dev/null || true
        ip link del "$VH" 2>/dev/null || true

        ip netns add "$NS"
        mkdir -p "/etc/netns/$NS"
        echo "nameserver 8.8.8.8" > "/etc/netns/$NS/resolv.conf"

        ip link add "$VH" type veth peer name "$VN"
        ip link set "$VN" netns "$NS"

        ip addr add "$HOST_IP/24" dev "$VH"
        ip link set "$VH" up

        ip -n "$NS" link set lo up
        ip -n "$NS" addr add "$NS_IP/24" dev "$VN"
        ip -n "$NS" link set "$VN" up
        ip -n "$NS" route add default via "$HOST_IP"

        if [ -n "''${SUDO_USER:-}" ]; then
          _UID=$(id -u "$SUDO_USER")
          ip netns exec "$NS" \
            sudo -u "$SUDO_USER" \
            env \
              HOME="$(eval echo ~"$SUDO_USER")" \
              XDG_RUNTIME_DIR="/run/user/$_UID" \
              DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$_UID/bus" \
              WAYLAND_DISPLAY="''${WAYLAND_DISPLAY:-wayland-1}" \
              -- ${command}
        else
          ip netns exec "$NS" ${command}
        fi
      '';
    };
}
