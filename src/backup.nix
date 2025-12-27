{
  lib,
  pkgs,
  self,
  ...
}:

let
  scripts = builtins.mapAttrs (
    _: fn:
    fn {
      inherit pkgs;
      name = "backup";
    }
  ) self.lib.backup;

  sudo = pkgs.writeShellApplication {
    name = "sudo";
    text = ''
      echo "$SUDOPASS" | /run/wrappers/bin/sudo -S "$@"
    '';
  };
in
{
  packageNixpkgs.config.allowUnfree = true;
  package = pkgs.writeShellApplication {
    name = "backup";
    runtimeInputs = with pkgs; [
      coreutils
      gnutar
      gzip
      age
      sudo
    ];
    text = ''
      PASS="$1"
      export SUDOPASS="$PASS"
      AGE_KEY="$2"
      TARGET_FILE="$3"
      WORK_DIR=$(mktemp -d)
      PWD=$(pwd)
      cd "$WORK_DIR"

      printf "📦 [Backup] Starting backup sequence."

      ${lib.concatStringsSep "\n" (
        lib.mapAttrsToList (name: pkg: ''
          SERVICE_DIR="$WORK_DIR/${name}"
          mkdir -p "$SERVICE_DIR"
          printf "▶️  [Backup] Running %s...\n" "${name}"

          if ${lib.getExe pkg} "$SERVICE_DIR"; then
            printf "✅ [Backup] %s completed\n" "${name}"
          else
            printf "❌ [Backup] %s failed\n" "${name}"
            exit 1
          fi
        '') scripts
      )}

      printf "🔒 [Backup] Compressing and Encrypting...\n"

      sudo chown -R "''${USER}:''${USER}" .
      if tar -C "$WORK_DIR" -czf - . | age -r "$AGE_KEY" > "$TARGET_FILE"; then
        printf "✅ [Backup] Encrypted archive created at %s\n" "$TARGET_FILE"
      else
        printf "❌ [Backup] Encryption failed\n"
        exit 1
      fi

      cd "$PWD"
      rm -rf "$WORK_DIR"
      printf "🎉 [Backup] All systems go.\n"
    '';
  };
}
