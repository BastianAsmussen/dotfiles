pkgs: {
  enable = true;

  settings = {
    server = {
      load_vscode_settings = true;
      default_settings.rust-analyzer = {
        check.command = "clippy";
        assist = {
          emitMustUse = true;
          expressionFillDefault = "default";
        };

        completion.termSearch.enable = true;
        diagnostics.styleLints.enable = true;
        imports = {
          granularity.enforce = true;
          preferPrelude = true;
        };

        inlayHints = {
          closureReturnTypeHints.enable = "always";
          closureStyle = "rust_analyzer";
          lifetimeElisionHints.enable = "skip_trivial";
        };

        typing.autoClosingAngleBrackets.enable = true;
      };

      dap.adapter = {
        command = "${pkgs.lldb}/bin/lldb-dap";
        type = "executable";
      };
    };
  };
}
