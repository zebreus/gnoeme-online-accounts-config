{ ... }: {
  config = {
    services.gnome-online-accounts = {
      enable = true;
    };
    services.gnome-online-accounts.accounts = {
      alpha = {
        Thing = true;
      };
    };
  };
}
