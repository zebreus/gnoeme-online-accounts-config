{ ... }: {
  config = {
    services.gnome-online-accounts.accounts = {
      alpha = {
        Thing = true;
      };
    };
  };
}
