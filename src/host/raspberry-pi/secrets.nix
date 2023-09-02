{}:

{
  sops.defaultSopsFile = ../../secrets.yaml;
  sops.secrets."server.crt".path = "/var/lib/postgresql/14/server.crt";
  sops.secrets."server.crt".owner = "postgres";
  sops.secrets."server.crt".group = "postgres";
  sops.secrets."server.crt".mode = "0600";
  sops.secrets."server.key".path = "/var/lib/postgresql/14/server.key";
  sops.secrets."server.key".owner = "postgres";
  sops.secrets."server.key".group = "postgres";
  sops.secrets."server.key".mode = "0600";
  sops.secrets."passwords.sql".path = "/var/lib/postgresql/14/passwords.sql";
  sops.secrets."passwords.sql".owner = "postgres";
  sops.secrets."passwords.sql".group = "postgres";
  sops.secrets."passwords.sql".mode = "0600";
}
