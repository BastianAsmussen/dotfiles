prev:
prev.oh-my-posh.overrideAttrs (old: {
  src = prev.fetchFromGitHub {
    owner = "BastianAsmussen";
    repo = "oh-my-posh";
    rev = "c8f484e9f25e14020505f561853410a292ce8462";
    hash = "sha256-f5v4OtRjisWeggF06+Rkb13sRDw3Cvv/foUzzZpG7HY=";
  };

  vendorHash = "sha256-YaMW2BUFone3/19/FvT4f8GpfVJxtVBMIOziBhEQPmE=";

  postPatch =
    ''
      # Doesn't compile otherwise.
      rm segments/upgrade_test.go
    ''
    + old.postPatch;
})
