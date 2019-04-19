#!/bin/bash
/usr/local/openresty/bin/openresty &
/usr/bin/dumb-init gitlab-runner run --user=root --working-directory=/home/gitlab-runner
