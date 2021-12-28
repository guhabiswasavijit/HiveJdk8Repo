#!/bin/bash
touch /run/openrc/softlevel \
  && /etc/init.d/sshd start \
  && start-dfs.sh \
  && hdfs --daemon start namenode \
  && hdfs --daemon start datanode \
  && hdfs --daemon start portmap \
  && hdfs --daemon start nfs3 