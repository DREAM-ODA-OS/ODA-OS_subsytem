#!/bin/sh
#
# install PIP - Python package manager
#

. `dirname $0`/../lib_logging.sh

info "Installing PIP Python package manager ..."

yum --assumeyes install python-pip
