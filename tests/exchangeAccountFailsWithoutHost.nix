# Define some email accounts and assert that the result looks correct
{ ... }: {
  config = {
    accounts.email.accounts = {
      exchangeTest = {
        primary = true;
        # flavor = "gmail.com";
        address = "testperson@gmail.com";
        realName = "Test Person";
        gnome-online-accounts = {
          enable = true;
          provider = "exchange";
        };
      };
    };
  };
}
