#
# common definitions shared by all ingestion engine scripts
#
#

export PATH="/srv/odaos/beam/bin:$PATH"
export PATH="/srv/odaos/tools/metadata:$PATH"
export PATH="/srv/odaos/tools/imgproc:$PATH"
export DJANGO_SETTINGS_MODULE="eoxs.settings"

LOG_FILE="/var/log/odaos/ie_actions.log"

EXENAME=`basename $0`

EOXS_MNG="/usr/bin/python /srv/odaos/eoxs/manage.py"

_remove() { for _file in $* ; do [ -f "$_file" ] && rm -fv "$_file" ; done ; }
_expand() { cd $1 ; pwd ; }

_date() { date -u --iso-8601=seconds | sed -e 's/+0000/Z/' ; }

_print()
{
    MSG="`_date` $EXENAME: $*"
    echo "$MSG"
    echo "$MSG" >> "$LOG_FILE"
}

error() { _print "ERROR: $*" ; }
info()  { _print "INFO: $*" ; }
warn()  { _print "WARNING: $*" ; }

# global warp options
WOPT="-multi -wo NUM_THREADS=2 -et 0.25 -r lanczos -wm 256"

# global TIFF options
TOPT="-co TILED=YES -co COMPRESS=DEFLATE -co PREDICTOR=2 -co INTERLEAVE=PIXEL"

# add overview options
ADOOPT="--config COMPRESS_OVERVIEW DEFLATE --config PREDICTOR_OVERVIEW 2 --config INTERLEAVE_OVERVIEW PIXEL -r average"

# preferably use gdaladdo provided by the FWTools
if [ -f "/srv/odaos/fwtools/bin_safe/gdaladdo" ]
then
    GDALADDO="/srv/odaos/fwtools/bin_safe/gdaladdo"
else
    GDALADDO="`which gdaladdo`"
fi
