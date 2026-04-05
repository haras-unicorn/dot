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

      filers = builtins.concatStringsSep "," (
        builtins.map (
          host:
          host.system.services.seaweedfs.filers.dot.ip
          + ":"
          + (builtins.toString host.system.services.seaweedfs.filers.dot.httpPort)
        ) hosts
      );

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

      stateDir = config.services.seaweedfs.filers.dot.stateDir;
      backupDirRelative = "dot/backup/logical";
      backupDir = "${stateDir}/extern/${backupDirRelative}";
      mountDirRelative = "dot/backup/mount";
      mountDir = "${stateDir}/extern/${mountDirRelative}";
      cacheDirRelative = "dot/backup/cache";
      cacheDir = "${stateDir}/extern/${cacheDirRelative}";

      user = config.services.seaweedfs.filers.dot.user;
      group = config.services.seaweedfs.filers.dot.group;

      dataDir = "./seaweedfs";

      logicalBackupPackage = pkgs.writeShellApplication {
        name = "seaweedfs-logical-backup";
        runtimeInputs = [
          pkgs.util-linux
        ];
        text = ''
          rm -rf "${backupDir}"
          runuser -u "${user}" -g "${group}" -- mkdir -p "${backupDir}"
          rm -rf "${mountDir}"
          runuser -u "${user}" -g "${group}" -- mkdir -p "${mountDir}"
          rm -rf "${cacheDir}"
          runuser -u "${user}" -g "${group}" -- mkdir -p "${cacheDir}"

          systemd-run --unit seaweedfs-logical-backup-mount weed mount \
            -dir '${mountDir}' \
            -cacheDir '${cacheDir}' \
            -filer '${filers}' \
            -filer.path '/'
          systemctl is-active seaweedfs-logical-backup-mount
          while ! mountpoint -q "${mountDir}"; do
            sleep 1
          done
          shopt -s dotglob
          cp -a "${mountDir}/"* "${backupDir}"
          shopt -u dotglob
          systemctl stop seaweedfs-logical-backup-mount
          umount "${mountDir}" || true
          fusermount -u "${mountDir}" || true
          fusermount3 -u "${mountDir}" || true
          while mountpoint -q "${mountDir}"; do
            umount "${mountDir}" || true
            fusermount -u "${mountDir}" || true
            fusermount3 -u "${mountDir}" || true
          done
          ls -la "${mountDir}"

          mv "${backupDir}" "${dataDir}"
          chown -R "$(id -un):$(id -gn)" "${dataDir}"

          rm -rf "${mountDir}"
          rm -rf "${cacheDir}"
        '';
      };

      logicalRestorePackage = pkgs.writeShellApplication {
        name = "seaweedfs-logical-restore";
        runtimeInputs = [
          pkgs.util-linux
        ];
        text = ''
          rm -rf "${backupDir}"
          runuser -u "${user}" -g "${group}" -- mkdir -p "$(dirname "${backupDir}")"
          rm -rf "${mountDir}"
          runuser -u "${user}" -g "${group}" -- mkdir -p "${mountDir}"
          rm -rf "${cacheDir}"
          runuser -u "${user}" -g "${group}" -- mkdir -p "${cacheDir}"

          mv "${dataDir}" "${backupDir}"
          chown -R "${user}:${group}" "${backupDir}"

          systemd-run --unit seaweedfs-logical-restore-mount weed mount \
            -dir '${mountDir}' \
            -cacheDir '${cacheDir}' \
            -filer '${filers}' \
            -filer.path '/'
          systemctl is-active seaweedfs-logical-restore-mount
          while ! mountpoint -q "${mountDir}"; do
            sleep 1
          done
          shopt -s dotglob
          mv "${backupDir}/"* "${mountDir}"
          shopt -u dotglob
          systemctl stop seaweedfs-logical-restore-mount
          umount "${mountDir}" || true
          fusermount -u "${mountDir}" || true
          fusermount3 -u "${mountDir}" || true
          while mountpoint -q "${mountDir}"; do
            umount "${mountDir}" || true
            fusermount -u "${mountDir}" || true
            fusermount3 -u "${mountDir}" || true
          done
          ls -la "${mountDir}"

          rm -rf "${backupDir}"
          rm -rf "${mountDir}"
          rm -rf "${cacheDir}"
        '';
      };

      physicalBackupPackage = pkgs.writeShellApplication {
        name = "seaweedfs-physical-backup";
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

      physicalRestorePackage = pkgs.writeShellApplication {
        name = "seaweedfs-physical-restore";
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
      dot.backup.physical.files = [ (lib.getExe physicalBackupPackage) ];
      dot.restore.physical.files = [ (lib.getExe physicalRestorePackage) ];
      dot.backup.logical.files = [ (lib.getExe logicalBackupPackage) ];
      dot.restore.logical.files = [ (lib.getExe logicalRestorePackage) ];
    };
}
