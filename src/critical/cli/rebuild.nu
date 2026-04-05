def --wrapped "main rebuild switch" [
  ...args: string
] {
  (sudo nixos-rebuild switch
    --flake $"(dot flake)#(hostname)"
    ...($args))
}

def --wrapped "main rebuild boot" [
  ...args: string
] {
  (sudo nixos-rebuild boot
    --flake $"(dot flake)#(hostname)"
    ...($args))
}

