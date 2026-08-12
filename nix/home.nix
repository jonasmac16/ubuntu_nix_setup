{ config, pkgs, hostname, ... }:

# Home Manager entry point. The flake passes the target hostname explicitly so
# evaluation is deterministic and does not depend on the machine running Nix.
let
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
