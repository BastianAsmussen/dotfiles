rec {
  default = rust;
  go = {
    path = ./go;
    description = "Go development environment.";
    welcomeText = ''
      # Go Project Template

      ## Intended Usage

      Development of Go programs and libraries.

      ## Notes

      Remember to change project name!

      I highly recommend giving Adam Hoese's
      [gomod2nix blog post](https://www.tweag.io/blog/2021-03-04-gomod2nix) a
      read before continuing.
    '';
  };

  python = {
    path = ./python;
    description = "Python development environment.";
    welcomeText = ''
      # Python Project Template

      ## Intended Usage

      Development and packaging of Python scripts and libraries.

      ## Notes

      Do not forget to change the `pyproject.toml`'s `tool.poetry.name` field!
    '';
  };

  rust = {
    path = ./rust;
    description = "Rust development environment.";
    welcomeText = ''
      # Rust Project Template

      ## Intended Usage

      Development and packaging of Rust programs and libraries.

      ## Notes

      Do not forget to change the `Cargo.toml`'s `package.name` field!
    '';
  };
}
