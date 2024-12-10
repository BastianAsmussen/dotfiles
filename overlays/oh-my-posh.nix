prev:
prev.oh-my-posh.overrideAttrs (old: {
  src = prev.fetchFromGitHub {
    owner = "BastianAsmussen";
    repo = "oh-my-posh";
    rev = "6633293910518b2924917b1abd7fbfc7c566534d";
    hash = "sha256-ZRMoFUTms+dR9LXIXxUmueXNqREYFBHT9MmJvyZrdQQ=";
  };

  vendorHash = "sha256-YaMW2BUFone3/19/FvT4f8GpfVJxtVBMIOziBhEQPmE=";

  postPatch =
    ''
      # Doesn't compile otherwise.
      rm segments/upgrade_test.go
    ''
    + old.postPatch;
})
