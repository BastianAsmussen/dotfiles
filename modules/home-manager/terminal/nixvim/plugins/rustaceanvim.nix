{
  lib,
  config,
  pkgs,
}: {
  enable = true;

  settings = {
    server = {
      load_vscode_settings = true;
      default_settings.rust-analyzer = {
        cargo.features = "all";
        check = {
          command = "clippy";
          extraArgs = ["--"] ++ (lib.strings.splitString " " config.home.sessionVariables.RUSTFLAGS);
          allTargets = true;
        };

        assist = {
          emitMustUse = true;
          expressionFillDefault = "default";
        };

        completion = {
          termSearch.enable = true;
          fullFunctionSignatures.enable = true;
          privateEditable.enable = true;
        };

        diagnostics.styleLints.enable = true;
        imports = {
          granularity.enforce = true;
          preferPrelude = true;
        };

        inlayHints = {
          bindingModeHints.enable = true;
          closureReturnTypeHints.enable = "always";
          closureStyle = "rust_analyzer";
        };

        lens.references = {
          adt.enable = true;
          enumVariant.enable = true;
          method.enable = true;
        };

        interpret.tests = true;
        workspace.symbol.search.scope = "workspace_and_dependencies";
        typing.autoClosingAngleBrackets.enable = true;
      };

      dap.adapter = {
        command = "${pkgs.lldb}/bin/lldb-dap";
        type = "executable";
      };
    };
  };
}
