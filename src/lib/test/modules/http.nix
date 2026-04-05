{ self, ... }:

{
  libAttrs.test.modules.http =
    {
      lib,
      config,
      ...
    }:
    let
      httpPort = 80;
      httpsPort = 443;

      getIp = name: config.nodes."http-${name}".dot.host.ip;
    in
    {
      options.dot.test = {
        http = lib.mkOption {
          description = "HTTP test servers";
          default = { };
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                enable = (lib.mkEnableOption "HTTP test server") // {
                  default = true;
                };

                domains = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                  description = "List of domains to route to test HTTP server";
                };

                handler = lib.mkOption {
                  type = lib.types.str;
                  default = "";
                  description = ''
                    Python snippet to execute inside the handler function:

                    def _do(self, method: str):
                      now = datetime.now().isoformat()
                      id = str(uuid.uuid4())

                      parsed = urllib.parse.urlparse(self.path)
                      path = parsed._asdict()
                      params = urllib.parse.parse_qs(parsed.query)
                      content_length = int(self.headers.get('Content-Length', 0))
                      body = self.rfile.read(content_length).decode()
                      headers = dict(self.headers)

                      status_code = 200
                      response = 'OK'
                      content_type = 'text/plain'

                      ''${indentedHandler}

                      self.send_response(status_code)
                      self.send_header('Content-Type', content_type)
                      self.end_headers()
                      self.wfile.write(response.encode())
                  '';
                };
              };
            }
          );
        };
      };

      config = {
        dot.test.dns.zones = lib.mkMerge (
          builtins.map (
            { name, value }: lib.mkIf value.enable (self.lib.dns.routeToIp value.domains (getIp name))
          ) (lib.attrsToList config.dot.test.http)
        );

        dot.test.external = lib.mkMerge (
          builtins.map (
            { name, value }:
            lib.mkIf value.enable {
              "http-${name}" = {
                node = "http-${name}";
                protocol = "http";
                connection = {
                  port = httpPort;
                  address = getIp name;
                };
              };
              "https-${name}" = {
                node = "http-${name}";
                protocol = "https";
                connection = {
                  port = httpsPort;
                  address = getIp name;
                };
              };
            }
          ) (lib.attrsToList config.dot.test.http)
        );

        dot.test.commands.prefix = lib.mkMerge (
          builtins.map (
            { name, value }:
            let
              pythonName = builtins.replaceStrings [ "-" ] [ "_" ] name;
            in
            lib.mkIf value.enable (
              lib.mkBefore ''
                http_${pythonName}.wait_for_unit("http.service")
              ''
            )
          ) (lib.attrsToList config.dot.test.http)
        );

        nodes = lib.mkMerge (
          builtins.map (
            { name, value }:
            lib.mkIf value.enable {
              "http-${name}" =
                { config, pkgs, ... }:
                let
                  stateDir = "http";

                  indentedHandler = builtins.concatStringsSep "\n" (
                    lib.imap0 (index: line: if index == 0 then line else "      ${line}") (
                      lib.splitString "\n" value.handler
                    )
                  );

                  script = pkgs.writeText "http.py" ''
                    HTTP_PORT = ${builtins.toString httpPort}
                    HTTPS_PORT = ${builtins.toString httpsPort}
                    TLS_CERT = "${config.sops.secrets."http-public".path}"
                    TLS_KEY = "${config.sops.secrets."http-private".path}"
                    LOG_FILE = "/var/lib/${stateDir}/log.jsonl"
                    STORE_FILE = "/var/lib/${stateDir}/store.json"

                    import http.server
                    import socketserver
                    import json
                    import urllib.parse
                    from datetime import datetime
                    import os
                    import threading
                    from socketserver import ThreadingTCPServer
                    import ssl
                    import time
                    import sys
                    import signal
                    import traceback
                    import uuid

                    store = {}

                    def signal_handler(signum, frame):
                      print("Shutting down gracefully...")
                      http_server.shutdown()
                      https_server.shutdown()
                      sys.exit(0)

                    class HTTPHandler(http.server.BaseHTTPRequestHandler):
                      def log_message(self, format, *args):
                        print(f"[HTTP] {self.address_string()} - {format % args}")

                      def _do(self, method: str):
                        now = datetime.now().isoformat()
                        id = str(uuid.uuid4())

                        parsed = urllib.parse.urlparse(self.path)
                        path = parsed._asdict()
                        params = urllib.parse.parse_qs(parsed.query)
                        content_length = int(self.headers.get('Content-Length', 0))
                        body = self.rfile.read(content_length).decode()
                        headers = dict(self.headers)

                        status_code = 200
                        response = 'OK'
                        content_type = 'text/plain'

                        try:
                          ${indentedHandler}
                        except Exception as e:
                          print(f"[HTTP] ERROR: Handler raised exception {e}")
                          traceback.print_exc()

                        self.send_response(status_code)
                        self.send_header('Content-Type', content_type)
                        self.end_headers()
                        self.wfile.write(response.encode())

                        with open(LOG_FILE, 'a') as f:
                          data = {
                            'id': id,
                            'timestamp': now,
                            'store': store,
                            'request': {
                              'method': method,
                              'path': path,
                              'params': params,
                              'body': body,
                              'headers': headers
                            },
                            'response': {
                              'status_code': status_code,
                              'response': response,
                              'content_type': content_type
                            }
                          }
                          f.write(f"{json.dumps(data)}\n")

                        with open(STORE_FILE, 'w') as f:
                          data = {
                            'last_request': {
                              'id': id,
                              'timestamp': now
                            },
                            'records': store,
                          }
                          f.write(f"{json.dumps(data)}\n")

                      def do_GET(self):
                        self._do('GET')

                      def do_POST(self):
                        self._do('POST')

                      def do_PUT(self):
                        self._do('PUT')

                    try:
                      signal.signal(signal.SIGTERM, signal_handler)
                      signal.signal(signal.SIGINT, signal_handler)

                      os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)

                      print(f"[HTTP] Starting test HTTP server...")
                      print(f"[HTTP] Log file: {LOG_FILE}")
                      print(f"[HTTP] HTTP port: {HTTP_PORT}")
                      print(f"[HTTP] HTTPS port: {HTTPS_PORT}")
                      print(f"[HTTP] TLS cert: {TLS_CERT}")
                      print(f"[HTTP] TLS key: {TLS_KEY}")

                      http_server = ThreadingTCPServer(("0.0.0.0", HTTP_PORT), HTTPHandler)
                      https_server = ThreadingTCPServer(("0.0.0.0", HTTPS_PORT), HTTPHandler)

                      context = ssl.create_default_context(ssl.Purpose.CLIENT_AUTH)
                      context.load_cert_chain(certfile=TLS_CERT, keyfile=TLS_KEY)
                      https_server.socket = context.wrap_socket(https_server.socket, server_side=True)

                      http_thread = threading.Thread(target=http_server.serve_forever, daemon=True)
                      https_thread = threading.Thread(target=https_server.serve_forever, daemon=True)
                      http_thread.start()
                      https_thread.start()

                      print("[HTTP] Servers started successfully")

                      try:
                        while True:
                          time.sleep(3600)
                      except KeyboardInterrupt:
                        signal_handler(signal.SIGINT, None)
                    except Exception as e:
                      print(f"[HTTP] ERROR: {e}")
                      traceback.print_exc()
                      sys.exit(1)
                  '';
                in
                {
                  dot.test.openssl.enable = true;

                  systemd.services.http = {
                    description = "Test HTTP server";
                    after = [ "network.target" ];
                    wantedBy = [ "multi-user.target" ];
                    serviceConfig = {
                      AmbientCapabilities = "CAP_NET_BIND_SERVICE";
                      Type = "simple";
                      Restart = "always";
                      User = "http";
                      Group = "http";
                      StateDirectory = stateDir;
                      ExecStart = "${lib.getExe pkgs.python3} ${script}";
                    };
                  };

                  networking.firewall.allowedTCPPorts = [
                    httpPort
                    httpsPort
                  ];

                  users.users.http = {
                    isSystemUser = true;
                    group = "http";
                    description = "Test HTTP server system user";
                  };

                  users.groups.http = { };

                  sops.secrets."http-public" = {
                    owner = "http";
                    group = "http";
                    mode = "0400";
                  };

                  sops.secrets."http-private" = {
                    owner = "http";
                    group = "http";
                    mode = "0400";
                  };

                  cryl.sops.keys = [
                    "http-private"
                    "http-public"
                  ];

                  cryl.specification.imports = [
                    {
                      importer = "vault-file";
                      arguments = {
                        path = self.lib.vault.shared;
                        file = "openssl-ca-private";
                        allow_fail = true;
                      };
                    }
                    {
                      importer = "vault-file";
                      arguments = {
                        path = self.lib.vault.shared;
                        file = "openssl-ca-public";
                        allow_fail = true;
                      };
                    }
                    {
                      importer = "vault-file";
                      arguments = {
                        path = self.lib.vault.shared;
                        file = "openssl-ca-serial";
                        allow_fail = true;
                      };
                    }
                  ];

                  cryl.specification.generations = [
                    {
                      generator = "tls-leaf";
                      arguments = {
                        common_name = "dot";
                        organization = "Dot";
                        sans = [
                          "localhost"
                          "${config.dot.host.ip}"
                          "127.0.0.1"
                        ]
                        ++ value.domains;
                        config = "http-cert-config";
                        request_config = "http-cert-request-config";
                        private = "http-private";
                        request = "http-cert-request";
                        ca_private = "openssl-ca-private";
                        ca_public = "openssl-ca-public";
                        serial = "openssl-ca-serial";
                        public = "http-public";
                        renew = true;
                      };
                    }
                  ];
                };
            }
          ) (lib.attrsToList config.dot.test.http)
        );
      };
    };
}
