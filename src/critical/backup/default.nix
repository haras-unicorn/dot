{
  flake.nixosModules.critical-backup =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      physicalBackupPackage = pkgs.writeShellApplication {
        name = "dot-physical-backup";
        runtimeInputs = with pkgs; [
          gzip
          gnutar
          openssl
          openssh
          ssh-to-age
          age
        ];
        text =
          let
            files =
              config.dot.backup.physical.files
              ++ (builtins.map (
                script: pkgs.writeScript "physical-backup-script" script
              ) config.dot.backup.physical.scripts);

            commands = lib.concatStringsSep "\n" (builtins.map (file: "${file}") files);
          in
          ''
            PWD=$(pwd)
            EXPORT_DIR="$PWD/backup-$(date +"%Y%m%d%H%M%S")"
            mkdir -p "$EXPORT_DIR"
            WORK_DIR=$(mktemp -d)
            DATA_DIR="$WORK_DIR/data"
            mkdir -p "$DATA_DIR"

            cd "$DATA_DIR"
            ${commands}

            cd "$WORK_DIR"
            openssl rand -base64 6 > pass # NOTE: 6 for 8 characters
            PASS="$(cat pass)"
            ssh-keygen -a 100 -t ed25519 -C backup -N "$(cat ./pass)" -f ./ssh
            mv ssh ssh-private; mv ssh.pub ssh-public
            ssh-to-age -i ssh-public -o age-public
            SSH_TO_AGE_PASSPHRASE="$(cat pass)" ssh-to-age -private-key -i ssh-private -o age-private
            tar -C "$DATA_DIR" -czf - . | age -R age-public > backup.tar.gz.age || exit 1
            mv ssh-public ssh-private backup.tar.gz.age "$EXPORT_DIR"

            cd "$PWD"
            rm -rf "$WORK_DIR"
            echo "Backup created at '$EXPORT_DIR' with password '$PASS'"
          '';
      };

      physicalRestorePackage = pkgs.writeShellApplication {
        name = "dot-physical-restore";
        runtimeInputs = with pkgs; [
          gzip
          gnutar
          openssl
          age
          systemd
          ssh-to-age
        ];
        text =
          let
            files =
              config.dot.restore.physical.files
              ++ (builtins.map (
                script: pkgs.writeScript "physical-restore-script" script
              ) config.dot.restore.physical.scripts);

            commands = lib.concatStringsSep "\n" (builtins.map (file: "${file}") files);
          in
          ''
            PWD="$(pwd)"
            WORK_DIR="$(mktemp -d)"
            DATA_DIR="$WORK_DIR/data"
            mkdir -p "$DATA_DIR"

            BACKUP_DIR="$(find backup-* -type d | sort -r | head -n 1)"
            if [ -z "$BACKUP_DIR" ]; then
              echo "No backup directory found." >&2
              exit 1
            fi
            cd "$BACKUP_DIR"

            INPUT="$(cat)"
            if [ -n "$INPUT" ]; then
              printf "%s" "$INPUT" > "$WORK_DIR/pass"
            elif [ ! -f pass ]; then
              PASS="$(systemd-ask-password --emoji=no --echo=no --timeout=0 "Enter backup passphrase:")"
              printf "%s" "$PASS" > "$WORK_DIR/pass"
            else
              cp pass "$WORK_DIR/pass"
            fi

            SSH_TO_AGE_PASSPHRASE="$(cat "$WORK_DIR/pass")" \
              ssh-to-age \
                -private-key \
                -i ssh-private \
                -o "$WORK_DIR/age-private" || {
              echo "SSH to AGE conversion failed." >&2
              rm -rf "$WORK_DIR"
              exit 1
            }

            age -d -i "$WORK_DIR/age-private" -o "$WORK_DIR/backup.tar.gz" backup.tar.gz.age || {
              echo "Decryption failed." >&2
              rm -rf "$WORK_DIR"
              exit 1
            }

            mkdir -p "$DATA_DIR"
            tar -xzf "$WORK_DIR/backup.tar.gz" -C "$DATA_DIR"

            cd "$DATA_DIR"
            ${commands}

            cd "$PWD"
            rm -rf "$WORK_DIR"
            echo "Restore complete from '$(basename "$BACKUP_DIR")'."
          '';
      };
    in
    {
      options.dot = {
        backup = {
          enable = lib.mkEnableOption "backup";
        };
      };

      config = lib.mkIf config.dot.backup.enable {
        environment.systemPackages = [
          physicalBackupPackage
          physicalRestorePackage
        ];
      };
    };
}
