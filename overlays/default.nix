_: {
  # Bring our custom packages from the 'pkgs' directory into scope.
  additions = final: _prev: import ../pkgs {pkgs = final;};
}
