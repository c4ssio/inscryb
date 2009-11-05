#!/bin/bash

mysqldump -ucassio_rails -p3x4lt1 cassio_inscrybdev | gzip > cassio_inscrybdev-`date +%Y%m%d`.sql.gz
mysqldump -ucassio_rails -p3x4lt1 cassio_inscrybprod | gzip > cassio_inscrybprod-`date +%Y%m%d`.sql.gz

