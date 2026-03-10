#!/usr/bin/env bash

# Get current directory without parents.
project_name=${PWD##*/}
project_name=${project_name:-/}

sed -i -e "s/sample-project/$project_name/g" ./Cargo.{toml,lock}

exit_code=$?
if [ "$exit_code" -gt 0 ]; then
	echo "Failed to initialize project!"
	exit $exit_code
fi

echo "Initialized project as '$project_name'."

# Clean up.
rm -- "$0"
