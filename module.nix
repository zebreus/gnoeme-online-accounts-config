{ pkgs, lib, config, ... }:
with lib;


let
  generateAccountsIni = lib.generators.toINI { mkSectionName = v: "Account ${v}"; };

  cfg = config.services.gnome-online-accounts;
in

{
  imports = [
    ./fixedConfig.nix
  ];

  options = {
    services.gnome-online-accounts = {
      enable = mkEnableOption "Enable GNOME Online Accounts support";
    };
  };
  config = lib.mkIf cfg.enable {
    home.file.".config/goa-1.0/accounts.conf".text = generateAccountsIni cfg.accounts;
  };
}
