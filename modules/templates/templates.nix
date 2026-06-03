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

        ## Notes

        Run `chmod +x init.sh && ./init.sh` to rename the project files automatically.
      '';
    };

    csharp = {
      path = ./_csharp;
      description = "C# development environment.";
      welcomeText = ''
        # C# Project Template

        ## Intended Usage

        Development of .NET console applications and libraries.

        ## Notes

        Run `chmod +x init.sh && ./init.sh` to rename the project files automatically.

        After adding NuGet packages, regenerate the lockfile. See `README.md` for
        the `fetch-deps` step.
      '';
    };

    haskell = {
      path = ./_haskell;
      description = "Haskell development environment.";
      welcomeText = ''
        # Haskell Project Template

        ## Intended Usage

        Development of Haskell programs and libraries with Cabal.

        ## Notes

        Run `chmod +x init.sh && ./init.sh` to rename the project files automatically.
      '';
    };

    zig = {
      path = ./_zig;
      description = "Zig development environment.";
      welcomeText = ''
        # Zig Project Template

        ## Intended Usage

        Development of Zig programs and libraries.

        ## Notes

        Run `chmod +x init.sh && ./init.sh` to rename the project files automatically.

        The toolchain is provided by [zig2nix](https://github.com/Cloudef/zig2nix),
        which keeps `zig` and `zls` in lock-step.
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
