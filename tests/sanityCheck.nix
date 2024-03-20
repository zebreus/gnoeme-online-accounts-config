# This is a correct configuration file for the GNOME Online Accounts service.
# It should not fail.
{
  services.gnome-online-accounts.enable = true;
  services.gnome-online-accounts.accounts = {
    account_1656063063_0 = {
      Provider = "google";
      Identity = "testperson@gmail.com";
      PresentationIdentity = "testperson@gmail.com";
      MailEnabled = true;
      CalendarEnabled = true;
      ContactsEnabled = true;
      PhotosEnabled = true;
      FilesEnabled = true;
      PrintersEnabled = true;
    };

    gamma = {
      Provider = "imap_smtp";
      Identity = "testperson@example.org";
      PresentationIdentity = "testperson@example.org";
      Enabled = true;
      EmailAddress = "testperson@example.org";
      Name = "Test Person";
      ImapHost = "email.example.org";
      ImapUserName = "testperson@example.org";
      ImapUseSsl = true;
      ImapUseTls = false;
      ImapAcceptSslErrors = false;
      SmtpHost = "smtp.example.org";
      SmtpUseAuth = true;
      SmtpUserName = "tperson";
      SmtpAuthLogin = false;
      SmtpAuthPlain = true;
      SmtpUseSsl = false;
      SmtpUseTls = true;
      SmtpAcceptSslErrors = false;
    };
  };
}
