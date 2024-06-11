{ lib, config, ... }:
with lib;
let
  cfg = config.services.gnome-online-accounts;
in
{
  imports = [
    ./fixedConfig.nix
  ];

  config = mkIf cfg.enable
    (mkIf (cfg.accounts != { }) {
      assertions =
        let
          accounts =
            mapAttrsToList
              (name: account: {
                name = name;
              } // account)
              cfg.accounts;
        in
        (builtins.concatMap
          (account: [
            # Useless, because the attributes are not allowed to be none anyway
            {
              assertion = account ? Provider;
              message = "gnome-online-accounts: Every account must specify a Provider. ${account.name} does not.";
            }
            {
              assertion = account ? Identity;
              message = "gnome-online-accounts: Every account must specify an Identity. ${account.name} does not.";
            }
          ])
          accounts);
    });
}
