{
  programs.nixvim.plugins.rustaceanvim = {
    enable = true;

    settings.server.default_settings.rust-analyzer = {
      check.command = "clippy";
      cargo.extraEnv.RUSTFLAGS = builtins.concatStringsSep " " [
        "-D clippy::correctness"
        "-D clippy::pedantic"
        "-D clippy::nursery"
        "-D clippy::suspicious"
        "-D clippy::allow_attributes"
        "-D clippy::cfg_not_test"
        "-D clippy::field_scoped_visibility_modifiers"
        "-W clippy::filetype_is_file"
        "-W clippy::perf"
        "-W clippy::complexity"
        "-W clippy::style"
        "-W clippy::cargo"
        "-W clippy::unwrap_used"
        "-W clippy::assertions_on_result_states"
        "-W clippy::clone_on_ref_ptr"
        "-W clippy::empty_drop"
        "-W clippy::empty_enum_variants_with_brackets"
        "-W clippy::empty_structs_with_brackets"
        "-W clippy::default_trait_access"
        "-W clippy::default_union_representation"
        "-W clippy::decimal_literal_representation"
        "-W clippy::arithmetic_side_effects"
        "-W clippy::shadow_same"
        "-D deprecated_safe"
        "-D let_underscore"
        "-D nonstandard_style"
        "-W rust_2024_compatibility"
        "-W future_incompatible"
        "-W keyword_idents"
      ];

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
  };
}
