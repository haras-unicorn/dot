{ lib, ... }:

let
  hexChars = lib.stringToCharacters "0123456789abcdef";

  hexToDec =
    hex:
    builtins.foldl' (
      sum: char:
      let
        lowerChar = lib.toLower char;
        v = builtins.head (
          builtins.filter (i: builtins.elemAt hexChars i == lowerChar) (builtins.genList (n: n) 16)
        );
      in
      sum * 16 + v
    ) 0 (lib.stringToCharacters hex);
in
{
  libAttrs.hex.hexToDec = hexToDec;

  flake.tests.hex = {
    test-hex-zero = {
      expr = hexToDec "0";
      expected = 0;
    };
    test-hex-single-digit = {
      expr = hexToDec "a";
      expected = 10;
    };
    test-hex-single-digit-f = {
      expr = hexToDec "f";
      expected = 15;
    };
    test-hex-two-digits = {
      expr = hexToDec "10";
      expected = 16;
    };
    test-hex-ff = {
      expr = hexToDec "ff";
      expected = 255;
    };
    test-hex-100 = {
      expr = hexToDec "100";
      expected = 256;
    };
    test-hex-uppercase = {
      expr = hexToDec "ABC";
      expected = 2748;
    };
    test-hex-mixed-case = {
      expr = hexToDec "DeadBeef";
      expected = 3735928559;
    };
    test-hex-large = {
      expr = hexToDec "ffffffff";
      expected = 4294967295;
    };
    test-hex-new = {
      expr = hexToDec "beef";
      expected = 48879;
    };
  };
}
