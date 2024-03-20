# Define some email accounts and assert that the result looks correct
{ config, ... }: {
  config = {
    accounts.email.accounts = {
      alpha = {
        primary = true;
        address = "testperson@example.org";
        imap = {
          host = "mail.zebre.us";
          port = 993;
        };
        smtp = {
          host = "mail.zebre.us";
          port = 465;
        };
        realName = "Test Person";
        userName = "testperson@example.org";
        gnome-online-accounts = {
          enable = true;
        };
      };
      beta = {
        address = "testperson@example.org";
        imap = {
          host = "mail.zebre.us";
          port = 993;
        };
        smtp = {
          host = "mail.zebre.us";
          port = 465;
        };
        realName = "Test Person";
        userName = "testperson@example.org";
      };
      gmailSmtp = {
        primary = false;
        flavor = "gmail.com";
        address = "testperson@gmail.com";
        realName = "Test Person";
        gnome-online-accounts = {
          enable = true;
        };
      };
      gmailGoogle = {
        primary = false;
        # flavor = "gmail.com";
        address = "testperson@gmail.com";
        realName = "Test Person";
        gnome-online-accounts = {
          enable = true;
          provider = "google";
        };
      };
    };

    assertions = [
      {
        assertion = config.services.gnome-online-accounts.accounts.alpha_imap_smtp.Provider == "imap_smtp";
        message = "Provider for alpha is not imap_smtp";
      }
      {
        assertion = config.services.gnome-online-accounts.accounts ? beta_imap_smtp == false;
        message = "An account for beta was created, but it should not have been, because gnome-online-accounts is not enabled for beta";
      }
      {
        assertion = config.services.gnome-online-accounts.accounts.gmailSmtp_imap_smtp.Provider == "imap_smtp";
        message = "Provider for gmailSmtp is not imap_smtp";
      }
      {
        assertion = config.services.gnome-online-accounts.accounts.gmailGoogle_google.Provider == "google";
        message = "Provider for gmailGoogle is not google";
      }
      {
        assertion = config.services.gnome-online-accounts.accounts.gmailGoogle_google.SmtpHost == null;
        message = "gmailGoogle appears to have a SMTP config, even though it is not using SMTP";
      }
    ];
  };
}
