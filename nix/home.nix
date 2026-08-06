{ config, pkgs, ... }:

# Home Manager entry point. Imports the common configuration plus the
# host-specific module matching this machine's hostname — mirroring how
# Ansible selects host_vars/<hostname>.yml (see ansible/inventory.ini).
let
  hostname = builtins.replaceStrings [ "\n" "\r" ] [ "" "" ] (
    if builtins.pathExists /etc/hostname then
      builtins.readFile /etc/hostname
    else
      builtins.getEnv "HOSTNAME"
  );
  hostDir = toString ./hosts;
  hostModulePath = hostDir + "/" + hostname + ".nix";
  hostModule =
    if builtins.pathExists hostModulePath then
      import hostModulePath
    else
      abort ''
        No Home Manager host module found for this machine (hostname: "${hostname}").
        Create nix/hosts/${hostname}.nix, e.g. by copying an existing host file.
      '';
in
{
  imports = [
    ./common.nix
    hostModule
  ];
}
