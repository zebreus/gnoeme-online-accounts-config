# If there is an email account with gnome-online-accounts.enabled = true, the whole module should get enabled
{ config, ... }:
{
  accounts.email.accounts.alpha = {
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
    gnome-online-accounts.enable = true;
  };


  assertions = [{
    assertion = config.services.gnome-online-accounts.enable == true;
    message = "The module was not enabled, even though there is an email account with gnome-online-accounts.enabled = true.";
  }];
}
