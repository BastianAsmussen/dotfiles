rec {
  default = rust;
  python = {
    path = ./python;
    description = "Basic Python development environment.";
    welcomeText = ''
      # Python Project Template

      ## Notes

      This isn't a final version, I'd like to integrate stuff like `flake-utils`
      and other utilities. Not to mention testing through `nix flake check` and
      running through `nix run`.
    '';
  };

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
