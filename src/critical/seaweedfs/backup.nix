{
  flake.nixosModules.critical-seaweedfs-backup =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      hasNetwork = config.dot.hardware.network.enable;

      hosts = builtins.filter (
        host:
        if lib.hasAttrByPath [ "system" "dot" "seaweedfs" "enable" ] host then
          host.system.dot.seaweedfs.enable
        else
          false
      ) config.dot.host.hosts;

      mkHostShell =
        host:
        if host.name == config.dot.host.name then
          ""
        else
          ''ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null"'';

      mkHostRsyncShell =
        host: if host.name == config.dot.host.name then "" else ''-e '${mkHostShell host}' '';

      mkHostSshShell =
        host: if host.name == config.dot.host.name then "" else ''${mkHostShell host} ${host.ip}'';

      mkHostSource =
        host:
        if host.name == config.dot.host.name then
          "${host.system.services.seaweedfs.volumes.dot.dataDir}/"
        else
          "${host.ip}:${host.system.services.seaweedfs.volumes.dot.dataDir}/";

      mkHostOwnerGroup =
        host:
        host.system.services.seaweedfs.volumes.dot.user
        + ":"
        + host.system.services.seaweedfs.volumes.dot.group;

      backupPackage = pkgs.writeShellApplication {
        name = "seaweedfs-manual-physical-backup";
        runtimeInputs = [
          pkgs.openssh
          pkgs.rsync
        ];
        text = ''
          backupDir="./seaweedfs"
          mkdir -p "$backupDir"

          ${lib.concatMapStringsSep "\n" (host: ''
            ${mkHostSshShell host} systemctl stop "seaweedfs-filer@dot.service"
            ${mkHostSshShell host} systemctl stop "seaweedfs-volume@dot.service"
            ${mkHostSshShell host} systemctl stop "seaweedfs-master.service"
          '') hosts}

          ${lib.concatMapStringsSep "\n" (host: ''
            mkdir -p "$backupDir/${host.name}"
            rsync -avz --delete ${mkHostRsyncShell host} \
              "${mkHostSource host}" \
              "$backupDir/${host.name}/" \
              --chown "$(id -un):$(id -gn)"
          '') hosts}

          ${lib.concatMapStringsSep "\n" (host: ''
            ${mkHostSshShell host} systemctl start "seaweedfs-master.service"
            ${mkHostSshShell host} systemctl start "seaweedfs-volume@dot.service"
            ${mkHostSshShell host} systemctl start "seaweedfs-filer@dot.service"
          '') hosts}
        '';
      };

      restorePackage = pkgs.writeShellApplication {
        name = "seaweedfs-manual-physical-restore";
        runtimeInputs = [
          pkgs.openssh
          pkgs.rsync
          pkgs.systemd
        ];
        text = ''
          backupDir="./seaweedfs"

          ${lib.concatMapStringsSep "\n" (host: ''
            ${mkHostSshShell host} systemctl stop "seaweedfs-filer@dot.service"
            ${mkHostSshShell host} systemctl stop "seaweedfs-volume@dot.service"
            ${mkHostSshShell host} systemctl stop "seaweedfs-master.service"
          '') hosts}

          ${lib.concatMapStringsSep "\n" (host: ''
            rsync -avz --delete ${mkHostRsyncShell host} \
              "$backupDir/${host.name}/" \
              "${mkHostSource host}" \
              --chown "${mkHostOwnerGroup host}"
          '') hosts}

          ${lib.concatMapStringsSep "\n" (host: ''
            ${mkHostSshShell host} systemctl start "seaweedfs-master.service"
            ${mkHostSshShell host} systemctl start "seaweedfs-volume@dot.service"
            ${mkHostSshShell host} systemctl start "seaweedfs-filer@dot.service"
          '') hosts}
        '';
      };
    in
    lib.mkIf (hasNetwork && config.dot.seaweedfs.enable) {
      dot.backup.physical.files = [ (lib.getExe backupPackage) ];
      dot.restore.physical.files = [ (lib.getExe restorePackage) ];
    };
}
