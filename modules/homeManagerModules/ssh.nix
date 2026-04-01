{inputs, ...}: {
  flake.homeModules.ssh = {
    config,
    lib,
    ...
  }: {
    imports = [inputs.sops-nix.homeManagerModules.sops];

    # Declare a secret for the trusted host address so it is not hard-coded in
    # the public repository. The secret must be defined in nix-secrets as
    # "ssh-gpg-forward-host".
    sops.secrets."ssh-gpg-forward-host" = {};

    programs.ssh = {
      enable = true;

      # Only forward the GPG agent to explicitly trusted hosts. Forwarding to a
      # wildcard would expose private key operations to any remote administrator
      # — see the Matrix.org incident for why this is dangerous:
      # https://matrix.org/blog/2019/05/08/post-mortem-and-remediations-for-apr-11-security-incident/#ssh-agent-forwarding-should-be-disabled
      matchBlocks."trusted-gpg-host" = {
        host = "lambda";
        extraOptions = {
          RemoteForward = "/run/user/1000/gnupg/S.gpg-agent /run/user/1000/gnupg/S.gpg-agent.extra";
          StreamLocalBindUnlink = "yes";
        };
      };
    };
  };
}
