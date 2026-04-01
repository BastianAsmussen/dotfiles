{
  flake.templates = rec {
    default = rust;
    c = {
      path = ./_c;
      description = "C development environment.";
      welcomeText = ''
        # C Project Template

        ## Intended Usage

        Development of C programs and libraries.

        ## Getting Started

        - Enter the development shell with `nix develop`.
        - Run `cmake -B build && cmake --build build` to compile.
      '';
    };

    csharp = {
      path = ./_csharp;
      description = "C# development environment.";
      welcomeText = ''
        # C# Project Template

        ## Intended Usage

        Development of C# programs and libraries.

        ## Getting Started

        - Enter the development shell with `nix develop`.
        - Run `dotnet new console -n MyProject` to scaffold a new project.
      '';
    };

    go = {
      path = ./_go;
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

    haskell = {
      path = ./_haskell;
      description = "Haskell development environment.";
      welcomeText = ''
        # Haskell Project Template

        ## Intended Usage

        Development of Haskell programs and libraries.

        ## Getting Started

        - Enter the development shell with `nix develop`.
        - Run `cabal build` to compile.
      '';
    };

    python = {
      path = ./_python;
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
      path = ./_rust;
      description = "Rust development environment.";
      welcomeText = ''
        # Rust Project Template

        ## Getting Started

        - Enter the development shell with `nix develop`.
        - Run `chmod +x init.sh && ./init.sh` to rename the project files automatically.
      '';
    };
  };
}
