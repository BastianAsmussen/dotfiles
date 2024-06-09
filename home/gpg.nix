{ pkgs, ... }:
{
  enable = true;

  publicKeys = [
    { source = ../keys/17BC2AC739E1E1CB09D1EF8F405799C00700B6A3.asc; }
  ];
}

