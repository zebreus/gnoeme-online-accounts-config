# This is a correct configuration file for the GNOME Online Accounts service.
# It should not fail.
{ config, ... }:
{
  services.gnome-online-accounts.enable = true;
  services.gnome-online-accounts.accounts = {
    testperson = {
      Provider = "google";
      Identity = "testperson@gmail.com";
      PresentationIdentity = "testperson@gmail.com";
      MailEnabled = true;
    };
  };

  assertions = [{
    assertion = config.services.gnome-online-accounts.accounts.testperson.name == "testperson";
    message = "The account name was not set correctly";
  }];
}
