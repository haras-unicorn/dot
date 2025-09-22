{ lib, ... }:

let
  hexChars = lib.stringToCharacters "0123456789abcdef";
in
{
  flake.lib.hex.hexToDec =
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
}
