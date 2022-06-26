#!/bin/bash
set -ex
export BRANCH=$1

echo 'Started to deploy.'

ssh isucon11-qualify-1 "cd /home/isucon && \
  git checkout . && \
  git fetch && \
  git checkout $BRANCH && \
  git reset --hard origin/$BRANCH && \
  cd /home/isucon && \
  sudo rm -f /var/log/mysql/mariadb-slow.log && \
  sudo systemctl restart mariadb && \
  cd /home/isucon/webapp/go && \
  /home/isucon/local/go/bin/go build -o isucondition . && \
  sudo systemctl restart isucondition.go && \
  sudo systemctl restart nginx && \
  sudo sysctl -p && \
  cd /home/isucon"

echo 'Finished to deploy.'
