{ lib, self, ... }:

{
  libAttrs.dns.routeToIp =
    domains: ip:
    builtins.mapAttrs
      (
        _: domains:
        builtins.listToAttrs (
          builtins.map (domain: {
            name = domain;
            value = ip;
          }) domains
        )
      )
      (
        builtins.groupBy (
          domain:
          builtins.concatStringsSep "." (
            lib.reverseList (lib.take 2 (lib.reverseList (lib.splitString "." domain)))
          )
        ) domains
      );

  flake.tests.dns =
    let
      routeToIp = self.lib.dns.routeToIp;
    in
    {
      test-empty-domains = {
        expr = routeToIp [ ] "192.168.1.1";
        expected = { };
      };

      test-single-domain = {
        expr = routeToIp [ "example.com" ] "192.168.1.1";
        expected = {
          "example.com" = {
            "example.com" = "192.168.1.1";
          };
        };
      };

      test-multiple-domains-same-zone = {
        expr = routeToIp [ "a.example.com" "b.example.com" ] "10.0.0.1";
        expected = {
          "example.com" = {
            "a.example.com" = "10.0.0.1";
            "b.example.com" = "10.0.0.1";
          };
        };
      };

      test-mixed-tld-zones = {
        expr = routeToIp [ "test.co.uk" "test.org" ] "172.16.0.1";
        expected = {
          "co.uk" = {
            "test.co.uk" = "172.16.0.1";
          };
          "test.org" = {
            "test.org" = "172.16.0.1";
          };
        };
      };

      test-three-part-tld = {
        expr = routeToIp [ "sub.test.co.uk" ] "192.168.0.5";
        expected = {
          "co.uk" = {
            "sub.test.co.uk" = "192.168.0.5";
          };
        };
      };

      test-ipv6 = {
        expr = routeToIp [ "example.net" ] "2001:db8::1";
        expected = {
          "example.net" = {
            "example.net" = "2001:db8::1";
          };
        };
      };
    };
}
