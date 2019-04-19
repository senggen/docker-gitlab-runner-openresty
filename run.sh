#!/bin/bash
/usr/local/openresty/bin/openresty &
/usr/bin/dumb-init gitlab-runner --user=root --working-directory=/home/gitlab-runner
