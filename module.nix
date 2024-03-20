{ lib, config, pkgs, ... }: with lib;
let
  generateAccountsIni = lib.generators.toINI { mkSectionName = v: "Account ${v}"; };

  cfg = config.services.gnome-online-accounts;


in

{
  imports = [
    ./fixedConfig.nix
    ./emailAccounts.nix
  ];

  options = {
    services.gnome-online-accounts = {
      enable = mkEnableOption "Enable GNOME Online Accounts support";

      accounts = mkOption {
        default = { };
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


  };

  config = lib.mkIf cfg.enable {
    home.file.".config/goa-1.0" = {
      source = pkgs.writeTextFile {
        name = "accounts.conf";
        text = generateAccountsIni (lib.mapAttrs
          (name: value: (lib.filterAttrs (name: value: (name != "enable") && (name != "name") && (value != null)) value))
          (lib.filterAttrs (name: value: value.enable) cfg.accounts));
        destination = "/accounts.conf";
      };
    };
  };
}
