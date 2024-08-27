{pkgs, ...}: {
  programs.nixvim.extraPlugins = [
    (pkgs.vimUtils.buildVimPlugin {
      name = "cellular-automaton.nvim";
      src = pkgs.fetchFromGitHub {
        owner = "Eandrju";
        repo = "cellular-automaton.nvim";
        rev = "11aea08aa084f9d523b0142c2cd9441b8ede09ed";
        hash = "sha256-nIv7ISRk0+yWd1lGEwAV6u1U7EFQj/T9F8pU6O0Wf0s=";
      };
    })
  ];
}
