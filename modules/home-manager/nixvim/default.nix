{inputs, ...}: {
  imports = [
    ./plugins

    inputs.nixvim.homeManagerModules.nixvim
  ];

  programs.nixvim = {
    enable = true;

    opts = {
      number = true;
      shiftwidth = 4;
    };

    keymaps = [
      {
        key = ";";
        action = ":";
      }
    ];
  };
}
