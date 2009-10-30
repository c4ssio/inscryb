#!/bin/bash

echo " ===== New Run at `date` ================================ "

set -x

# simply reindex sphinx - the config will have all the deets
cd /home/cassio/rails/inscryb
/usr/local/bin/rake thinking_sphinx:index

set +x

