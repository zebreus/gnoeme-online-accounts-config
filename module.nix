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

    services.gnome-online-accounts.accounts = mkOption {
      type = types.attrsOf (types.submodule ({ lib, name, ... }: with lib;{
        options = {
          enable = mkOption {
            type = types.bool;
            default = true;
            description = "Enable this account. Will not be written to the configuration file.";
          };
          name = mkOption {
            type = types.str;
            readOnly = true;
            default = name;
            description = "The id of this account in the configuration file. Will not be written to the configuration file.";
          };
        };
      }));
    };
  };

  config = lib.mkIf cfg.enable {
    home.file.".config/goa-1.0/accounts.conf".text = generateAccountsIni (lib.filterAttrs
      (name: value: (name != "enable") && (name != "name") && (value != null))
      (lib.filterAttrs (name: value: value.enable) cfg.accounts));

    services.gnome-online-accounts.accounts = { };
  };
}
