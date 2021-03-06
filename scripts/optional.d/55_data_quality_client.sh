#!/bin/sh
#
# install data-quality client
#
#======================================================================

. `dirname $0`/../lib_logging.sh

info "Installing the improvised DQ Client ... "

#======================================================================

[ -z "$ODAOS_DQC_HOME" ] && error "Missing the required ODAOS_DQC_HOME variable!"
[ -z "$ODAOSROOT" ] && error "Missing the required ODAOSROOT variable!"
[ -z "$CONTRIB" ] && error "Missing the required CONTRIB variable!"
[ -z "$DQCLIENT" ] && error "Missing the required DQCLIENT variable!"
[ -z "$ODAOSUSER" ] && error "Missing the required ODAOSUSER variable!"
[ -z "$ODAOSGROUP" ] && error "Missing the required ODAOSGROUP variable!"

#======================================================================

sudo -u "$ODAOSUSER" mkdir -p "$ODAOS_DQC_HOME/lib/mwps"
sudo -u "$ODAOSUSER" cp -fv "$DQCLIENT/pq.html" "$ODAOS_DQC_HOME/pq.html"
sudo -u "$ODAOSUSER" cp -fv "$DQCLIENT/mwps/mwps.js" "$ODAOS_DQC_HOME/lib/mwps/mwps.js"
sudo -u "$ODAOSUSER" cp -fv "$DQCLIENT/mwps/mwps.min.js" "$ODAOS_DQC_HOME/lib/mwps/mwps.min.js"

# reset the right URL in the client
DQ_URL="http://${HOSTNAME}/constellation/WS/wps/dream"
if [ -f "$ODAOS_DQC_HOME/pq.html" ]
then
    { ex "$ODAOS_DQC_HOME/pq.html" || /bin/true ; } <<END
%s#\(wpsUrl[ 	]*=[ 	]*"\)[^"']*\(["']\)#\1$DQ_URL\2#
wq
END
fi

#======================================================================

info "Improvised DQ Client installed."
