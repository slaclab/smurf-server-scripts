#!/bin/bash

target_dir_prefix=system

goto_script install/install-system-common.sh $@

echo "Scripts placed in ${target_dir}"
echo "End of release-system.sh"
