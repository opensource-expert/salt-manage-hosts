#!/bin/bash
#
# for managed server, bootstrap our node
# Usage:
#  bootstrap-node.sh hostname.fqdn
#
# Usage on the node:
#  bootstrap-node.sh -n hostname.fqdn
#
# Usage in debug mode (on the node):
#  . bootstrap-node.sh
#  apt_bootstrap
#  change_hostname hostname.fqdn
#  admin_ssh_config
#  …
#
# How it's desined:
#  the same script is a wrapper to be executed on the master with argument
#  which will be copied to the node (minion) and re-executed locally with
#  the good argument.
#

# add additional package
packages="vim git etckeeper locate"
# joe editor par défaut ??
packages_remove="joe"

# SET YOUR MASTER HOST NAME HERE !
saltmaster="saltmaster.domain.com"

apt_bootstrap() {
  apt-get update
  apt-get install -y $packages
  apt-get remove -y --purge $packages_remove
}

admin_ssh_config() {
  mkdir -p ~/.ssh
  cat << EOT > .ssh/config
ForwardAgent yes
HashKnownHosts no
EOT
}

restore_old_hostname() {
  if [[ -e /root/hostname.old ]]
  then
    cp /root/hostname.old /etc/hostname
  fi

  if [[ -e /root/hostname.old ]]
  then
    cp /root/hosts.old /etc/hosts
  fi
}

show_hostname_file() {
  echo verify
  set -x

  hostname -f
  ssh -A -o StrictHostKeyChecking=no -q localhost hostname

  # display
  more /etc/hosts /etc/hostname | cat

  set +x
}

get_myip() {
  ifconfig | perl -nle 'if(!/127.0.0.1/) { s/dr:(\S+)/print $1/e; }'
}

change_hostname() {
  if [[ -z "$1" ]]
  then
    echo "missing new hostname"
    return
  fi

  local minion="$1"

  if [[ "$(hostname -f)" == "$minion" ]]
  then
    echo "already ok, skipped"
    return
  fi

  # backup hostname
  echo backup
  cp /etc/hostname /root/hostname.old
  cp /etc/hosts /root/hosts.old

  # set hostname
  echo "$minion" > /etc/hostname
  # set it
  hostname -F  /etc/hostname
  # remove old name from /etc/hosts
  grep -v "$(cat /root/hostname.old)" /root/hosts.old > /etc/hosts
  # add new hostname.old
  echo "$(get_myip) $(hostname -f) $(hostname -s)" >> /etc/hosts

  # apply
  echo apply
  invoke-rc.d hostname.sh start
  invoke-rc.d networking force-reload

  # verify
  show_hostname_file
}

node_init() {
  local minion="$1"
  echo "node_init: $minion"
  echo "I'm $(hostname -f)"
  apt_bootstrap
  change_hostname "$minion"
}

main() {
  # minion is a valid dns name to reach the host via ssh
  local minion="$1"

  if [[ "$1" == '-n' ]]
  then
    minion="$2"
    node_init "$minion"
  else
    # one-liner upload and execute the script on the node
    cat "$0" | ssh -A -o StrictHostKeyChecking=no -q "$minion" \
      "t=/tmp/boot;cat> \$t && bash \$t -n '$minion'; rm \$t"
    # send minion bootstrap
    cat ~/salt-bootstrap/bootstrap-salt.sh | ssh "$minion" \
      "t=/tmp/boot2;cat> \$t &&
      bash \$t -A $saltmaster stable ; \\
      rm \$t"
  fi
}

# sourcing code detection, if code is sourced for debug purpose, main is not executed.
[[ $0 != "$BASH_SOURCE" ]] && sourced=1 || sourced=0
if  [[ $sourced -eq 0 ]]
then
    # pass positional argument as is
    main "$@"
fi
