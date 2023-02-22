#!/usr/bin/env bash

set -o pipefail
set -o nounset
set -o errexit

echo "linux kernel info"
uname -r
rpm -qa | grep kernel
amazon-linux-extras | grep kernel

case $(uname -r) in
    5.10.*)
        echo "already using a 5.10 kernel version"
        ;;
    *)
        echo "use linux kernel 5.10"
        if yum versionlock | grep 'kernel'; then
            yum versionlock delete 'kernel'
        fi
        amazon-linux-extras disable kernel-5.4
        amazon-linux-extras install kernel-5.10 -y
        rpm -qa | grep 'kernel'

        echo "rebooting the instance"
        reboot
        ;;
esac
