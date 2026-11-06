{
  flake.homeModules.learnharness =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.learnharness ];

      # Chats, the knowledge graph, and auth.json with provider keys.
      persistence.directoriesWithMode.".config/LearnHarness" = "0700";
    };
}
