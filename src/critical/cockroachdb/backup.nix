{
  flake.nixosModules.critical-cockroachdb-backup =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      hasNetwork = config.dot.hardware.network.enable;

      stateDirRelative = config.systemd.services.cockroachdb.serviceConfig.StateDirectory;
      stateDir = "/var/lib/${stateDirRelative}";
      backupDirRelative = "dot/backup/logical";
      backupDir = "${stateDir}/extern/${backupDirRelative}";

      dataDir = "./cockroachdb";

      user = config.services.cockroachdb.user;
      group = config.services.cockroachdb.group;

      hosts = builtins.filter (
        x:
        if lib.hasAttrByPath [ "system" "dot" "cockroachdb" "enable" ] x then
          x.system.dot.cockroachdb.enable
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
          "/var/lib/${host.system.systemd.services.cockroachdb.serviceConfig.StateDirectory}/"
        else
          "${host.ip}:/var/lib/${host.system.systemd.services.cockroachdb.serviceConfig.StateDirectory}/";

      mkHostOwnerGroup =
        host: host.system.services.cockroachdb.user + ":" + host.system.services.cockroachdb.group;

      physicalBackupPackage = pkgs.writeShellApplication {
        name = "cockroachdb-physical-backup";
        runtimeInputs = [
          pkgs.openssh
          pkgs.rsync
        ];
        text = ''
          backupDir="./cockroachdb"
          mkdir -p "$backupDir"

          ${lib.concatMapStringsSep "\n" (host: ''
            ${mkHostSshShell host} systemctl stop "cockroachdb.service"
          '') hosts}

          ${lib.concatMapStringsSep "\n" (host: ''
            mkdir -p "$backupDir/${host.name}"
            rsync -avz --delete ${mkHostRsyncShell host} \
              "${mkHostSource host}" \
              "$backupDir/${host.name}/" \
              --chown "$(id -un):$(id -gn)"
          '') hosts}

          ${lib.concatMapStringsSep "\n" (host: ''
            ${mkHostSshShell host} systemctl start "cockroachdb.service"
          '') hosts}
        '';
      };

      physicalRestorePackage = pkgs.writeShellApplication {
        name = "cockroachdb-physical-restore";
        runtimeInputs = [
          pkgs.openssh
          pkgs.rsync
          pkgs.systemd
        ];
        text = ''
          backupDir="./cockroachdb"

          ${lib.concatMapStringsSep "\n" (host: ''
            ${mkHostSshShell host} systemctl stop "cockroachdb.service"
          '') hosts}

          ${lib.concatMapStringsSep "\n" (host: ''
            rsync -avz --delete ${mkHostRsyncShell host} \
              "$backupDir/${host.name}/" \
              "${mkHostSource host}" \
              --chown "${mkHostOwnerGroup host}"
          '') hosts}

          ${lib.concatMapStringsSep "\n" (host: ''
            ${mkHostSshShell host} systemctl start "cockroachdb.service"
          '') hosts}
        '';
      };

      logicalBackupPackage = pkgs.writeShellApplication {
        name = "cockroachdb-logical-backup";
        runtimeInputs = [
          pkgs.util-linux
        ];
        text = ''
          rm -rf "${backupDir}"
          runuser -u "${user}" -g "${group}" -- mkdir -p "${backupDir}"

          dot cockroachdb root sql \
            -e "BACKUP INTO 'nodelocal://self/${backupDirRelative}';"

          mv "${backupDir}" "${dataDir}"
          chown -R "$(id -un):$(id -gn)" "${dataDir}"
        '';
      };

      logicalRestorePackage = pkgs.writeShellApplication {
        name = "cockroachdb-logical-restore";
        runtimeInputs = [
          pkgs.util-linux
        ];
        text = ''
          rm -rf "${backupDir}"
          runuser -u "${user}" -g "${group}" -- mkdir -p "$(dirname "${backupDir}")"
          mv "${dataDir}" "${backupDir}"
          chown -R "${user}:${group}" "${backupDir}"

          dot cockroachdb root sql \
            -e "RESTORE FROM LATEST IN 'nodelocal://self/${backupDirRelative}';"

          rm -rf "${backupDir}"
        '';
      };
    in
    lib.mkIf hasNetwork {
      dot.backup.physical.files = [ (lib.getExe physicalBackupPackage) ];
      dot.restore.physical.files = [ (lib.getExe physicalRestorePackage) ];
      dot.backup.logical.files = [ (lib.getExe logicalBackupPackage) ];
      dot.restore.logical.files = [ (lib.getExe logicalRestorePackage) ];
    };
}
