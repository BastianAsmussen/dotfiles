{
  userInfo,
  pkgs,
  ...
}: let
  inherit (userInfo) username fullName icon;
in {
  programs.zsh.enable = true;

  users.users.${username} = {
    isNormalUser = true;
    description = fullName;
    initialPassword = "Password123!";
    extraGroups = ["wheel"];
    shell = pkgs.zsh;
    openssh.authorizedKeys = {
      keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC6tLYigg7LbophUDTyIp1QtrduZJFAhxqcKrn+bfvZpSw7cezQYupjPxSANJB5ujblc35UDfJXl+Bc9exzIugmYdQ4GnxQCmarc/I+l+P/MPRl0K2vAzxA/ifcecHAjBen9Nu6sSA2HxxiQ+x+7pS+Q15wUDji5pz9ENCd7G1veLpoEg+ZKtQDsPHuMGDnAAHdHRQXxAt6TDVaIYjxTjNCHYwczKYaGYJEckYnJNwqIcTMOvmI2h0mzhBVjMAYA9uqr7cmoJHwD+v3/78o1wVdQcNI5EW7t0LmDs0wLCN5cKNUWMKr7DuP3xLe+cJXgiNyHqBVoRq2FFraIktt0++KgZ/p+F/uNSbQ+ZNoW8Usragnhz4hvNDZ1nJrEt0DjFeU4lhpczvJrMYi3cmzjMSewBWZtZK9eccIjlRLPfqmt6jO0hAOBi8n0aXK4jmpG4CBfnvCZ8nW7YwTuVlzQRHgNZFs6FUcxx/yXQTHnTnQ9jT7ucoVpKQuP73x6vNIc/HFK5G3BMXsuBuz3DdEyKYhEbtlrfrXWQmX8Yp7Axglw2JMrukGIxVaMtN3vJC9VQlZMe0Lk8mBtEa0Ny9S3MSLeIL6DO39VSnx07WNHB7donYam2CP92OrIYVT2aBJkSWETDlBI4Ku6p7eZQj7TRhhWR0FMYkTVI+eJ9z/gIHOrw== cardno:26_268_691"
      ];

      keyFiles = [../../keys/work.pub];
    };
  };

  # Set the user's icon.
  system.activationScripts.script.text = ''
    mkdir -p /var/lib/AccountsService/{icons,users}

    cp ${icon} /var/lib/AccountsService/icons/${username}
    echo -e "[User]\nIcon=/var/lib/AccountsService/icons/${username}\n" > /var/lib/AccountsService/users/${username}
  '';
}
