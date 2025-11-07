{inputs, ...}: {
  perSystem = {pkgs, ...}: {
    packages.git = inputs.wrappers.lib.wrapPackage {
      inherit pkgs;

      package = pkgs.git;
      env = rec {
        GIT_AUTHOR_NAME = "Bastian Asmussen";
        GIT_AUTHOR_EMAIL = "bastian@asmussen.tech";
        GIT_COMMITTER_NAME = GIT_AUTHOR_NAME;
        GIT_COMMITTER_EMAIL = GIT_AUTHOR_EMAIL;
      };
    };
  };
}
