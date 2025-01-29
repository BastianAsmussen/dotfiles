rec {
  default = rust;
  rust = {
    path = ./rust;
    description = "Standard Rust development environment.";
    welcomeText = ''
      # Rust Project Template

      ## Intended Usage

      Development and packaging of Rust programs and libraries.

      ## Notes

      Do not forget to change the `Cargo.toml`'s `package.name` field!
    '';
  };
}
