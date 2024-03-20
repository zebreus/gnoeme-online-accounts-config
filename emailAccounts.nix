{ config, lib, ... }:
with lib;
let
  cfg = config.services.gnome-online-accounts;

  emailAccount = { config, lib, ... }: with lib;{
    options.gnome-online-accounts = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable mail for this account in GNOME Online Accounts.
        '';
      };

      provider = mkOption {
        type = types.enum [ "imap_smtp" "google" "exchange" "windows_live" ];
        default = "imap_smtp";
        description = ''
          Whether to create an IMAP/SMTP account or use a more specific provider.

          For google and windows_live only the `userName` is required. `imap_smtp` requires valid IMAP and SMTP settings.
        '';
      };

      smtp.authMethod = mkOption {
        type = types.nullOr (types.enum [ "login" "plain" ]);
        default = "plain";
        description = ''
          The authentication method to use for the SMTP server.
        '';
      };

      smtp.acceptSslErrors = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Accept SSL/TLS errors caused by invalid certificates.

          See [](#opt-services.gnome-online-accounts.accounts._name_.SmtpAcceptSslErrors)
        '';
      };

      smtp.userName = mkOption {
        type = types.nullOr types.str;
        default = config.userName;
        description = ''
          The SMTP username for the account.
        '';
      };

      imap.acceptSslErrors = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Accept SSL/TLS errors caused by invalid certificates.

          See [](#opt-services.gnome-online-accounts.accounts._name_.ImapAcceptSslErrors)
        '';
      };

      imap.userName = mkOption {
        type = types.nullOr types.str;
        default = config.userName;
        description = ''
          The IMAP username for the account.
        '';
      };

      windowsLiveId = mkOption {
        type = types.nullOr types.str;
        default = config.userName;
        description = ''
          The Microsoft user ID for the account. Required if `provider` is set to "windows_live".

          Must not be null if the provider is "windows_live".
        '';
      };

      exchange = {
        host = mkOption {
          type = types.str;
          description = ''
            The hostname of the Exchange server. See [](#opt-services.gnome-online-accounts.accounts._name_.Host).
          '';
        };

        acceptSslErrors = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Accept SSL/TLS errors caused by invalid certificates.

            See [](#opt-services.gnome-online-accounts.accounts._name_.AcceptSslErrors)
          '';
        };
      };
    };
  };

  mailEnabledAccounts =
    filter (a: a.gnome-online-accounts.enable) (attrValues config.accounts.email.accounts);

  enableMailForAccount = account:
    let
      userNameOrAddress = if (account.userName != null) then account.userName else account.address;
    in
    {
      "${account.name}_${account.gnome-online-accounts.provider}" = (
        {
          imap_smtp = {
            Provider = "imap_smtp";
            Identity = userNameOrAddress;
            PresentationIdentity = account.address;
            MailEnabled = account.gnome-online-accounts.enable;
            Enabled = account.gnome-online-accounts.enable;
            EmailAddress = account.address;
            Name = account.realName;
            ImapHost = account.imap.host + (if account.imap.port != null then ":${toString account.imap.port}" else "");
            ImapUserName = account.gnome-online-accounts.smtp.userName;
            ImapUseSsl = account.imap.tls.enable && !account.imap.tls.useStartTls;
            ImapUseTls = account.imap.tls.enable && account.imap.tls.useStartTls;
            ImapAcceptSslErrors = account.gnome-online-accounts.imap.acceptSslErrors;
            SmtpHost = account.smtp.host + (if account.smtp.port != null then ":${toString account.smtp.port}" else "");
            SmtpUserName = account.gnome-online-accounts.smtp.userName;
            SmtpUseAuth = account.gnome-online-accounts.smtp.authMethod != null;
            SmtpAuthLogin = account.gnome-online-accounts.smtp.authMethod == "login";
            SmtpAuthPlain = account.gnome-online-accounts.smtp.authMethod == "plain";
            SmtpUseSsl = account.smtp.tls.enable && !account.smtp.tls.useStartTls;
            SmtpUseTls = account.smtp.tls.enable && account.smtp.tls.useStartTls;
            SmtpAcceptSslErrors = account.gnome-online-accounts.smtp.acceptSslErrors;
          };
          google = {
            Provider = "google";
            Identity = userNameOrAddress;
            PresentationIdentity = account.address;
            MailEnabled = account.gnome-online-accounts.enable;
            CalendarEnabled = mkDefault account.gnome-online-accounts.enable;
            ContactsEnabled = mkDefault account.gnome-online-accounts.enable;
            PhotosEnabled = mkDefault account.gnome-online-accounts.enable;
            FilesEnabled = mkDefault account.gnome-online-accounts.enable;
            PrintersEnabled = mkDefault account.gnome-online-accounts.enable;
          };
          windows_live = {
            Provider = "windows_live";
            Identity = account.gnome-online-accounts.windowsLiveId;
            PresentationIdentity = account.address;
            MailEnabled = account.gnome-online-accounts.enable;
          };
          exchange = {
            Provider = "exchange";
            Identity = userNameOrAddress;
            PresentationIdentity = account.address;
            Host = account.gnome-online-accounts.exchange.host;
            AcceptSslErrors = account.gnome-online-accounts.exchange.acceptSslErrors;
            MailEnabled = account.gnome-online-accounts.enable;
            CalendarEnabled = mkDefault account.gnome-online-accounts.enable;
            ContactsEnabled = mkDefault account.gnome-online-accounts.enable;
          };
        }.${account.gnome-online-accounts.provider}
      );
    };
in
{
  options = {
    accounts.email.accounts = mkOption {
      type = with types;
        attrsOf (submodule emailAccount);
    };
  };

  config = mkMerge [
    (mkIf (length mailEnabledAccounts != 0) {
      services.gnome-online-accounts.enable = true;
    })
    (mkIf cfg.enable {
      services.gnome-online-accounts.accounts = mkMerge
        (builtins.map (account: enableMailForAccount account) mailEnabledAccounts);
    })
  ];
}
