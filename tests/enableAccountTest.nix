# If an account is disabled, it should not fail if Provider is missing
{ ... }: {
  config = {
    services.gnome-online-accounts = {
      enable = true;
    };
    services.gnome-online-accounts.accounts = {
      alpha = {
        enable = false;
        Thing = true;
      };
    };
  };
}
