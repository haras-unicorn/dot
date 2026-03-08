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
      externDir = "dot/backup/manual/physical";
      backupDir = "${stateDir}/extern/${externDir}";

      dataDir = "./cockroachdb";

      user = config.services.cockroachdb.user;
      group = config.services.cockroachdb.group;

      backupPackage = pkgs.writeShellApplication {
        name = "cockroachdb-manual-physical-backup";
        runtimeInputs = [
          pkgs.util-linux
        ];
        text = ''
          rm -rf "${backupDir}"
          runuser -u "${user}" -g "${group}" -- mkdir -p "${backupDir}"

          node_id="$(dot-cockroach-root sql -e "SELECT node_id FROM crdb_internal.node_runtime_info;" | tail -n 1)"
          dot-cockroach-root sql -e "BACKUP DATABASE testdb INTO 'nodelocal://$node_id/${externDir}';"

          mv "${backupDir}" "${dataDir}"
          chown -R "$(id -un):$(id -gn)" "${dataDir}"
        '';
      };

      restorePackage = pkgs.writeShellApplication {
        name = "cockroachdb-manual-physical-restore";
        runtimeInputs = [
          pkgs.util-linux
        ];
        text = ''
          rm -rf "${backupDir}"
          runuser -u "${user}" -g "${group}" -- mkdir -p "$(dirname "${backupDir}")"
          mv "${dataDir}" "${backupDir}"
          chown -R "${user}:${group}" "${backupDir}"

          node_id="$(dot-cockroach-root sql -e "SELECT node_id FROM crdb_internal.node_runtime_info;" | tail -n 1)"
          dot-cockroach-root sql -e "RESTORE DATABASE testdb FROM LATEST IN 'nodelocal://$node_id/${externDir}';"

          rm -rf "${backupDir}"
        '';
      };
    in
    lib.mkIf
      (hasNetwork && config.dot.cockroachdb.enable && config.dot.cockroachdb.enableRootConnection)
      {
        dot.backup.physical.files = [ (lib.getExe backupPackage) ];
        dot.restore.physical.files = [ (lib.getExe restorePackage) ];
      };
}
