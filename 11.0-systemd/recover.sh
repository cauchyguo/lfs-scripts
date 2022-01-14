#!/bin/bash
# Recover Host OS
set -e

groupdel -f lfs
userdel -r -f lfs
[ ! -e /etc/bash.bashrc.NOUSE ] || mv -v /etc/bash.bashrc.NOUSE /etc/bash.bashrc
