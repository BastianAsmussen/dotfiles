#!/usr/bin/env bash

# Get current directory without parents.
project_name=${PWD##*/}
project_name=${project_name:-/}

# Renames the produced binary. The package identity in `build.zig.zon` is left
# alone: changing `.name` there requires a matching `.fingerprint`, which `zig
# build` prints for you on the next build.
sed -i -e "s/sample-project/$project_name/g" ./build.zig

exit_code=$?
if [ "$exit_code" -gt 0 ]; then
	echo "Failed to initialize project!"
	exit $exit_code
fi

echo "Initialized project as '$project_name'."

# Clean up.
rm -- "$0"
