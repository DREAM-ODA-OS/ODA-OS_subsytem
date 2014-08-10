#!/bin/bash
#
#  AddProduct action handler.
#
# USAGE:
#  product_add.sh [-replace=<existing_prod_id> | -add[=<collection>] ]
#    [-dldir=<download_directory>] -response=<filename>
#    -data=<datafile> [-meta=<metadatafile>]
#
# PARAMETERS:
#
#   -add[=<collection>] Indicates that a new product shall be
#                       registered. Optionally, collection to
#                       which the product shall be inserted
#                       can be specified.
#   -replace=<prod_id>  Indicates the an existing product
#                       shall be replaced.
#   -id=<prod_id>       Product identifier to be used with the -add
#                       option.
#                       shall be replaced.
#   -dldir=<dir>        Download directory.
#   -response=<file>    File where the response should be written.
#   -data=<file>        Datafile to be registered.
#   -metadata=<file>    Product's meta-data.
#
# DESCRIPTION:
#
# All files are relative to dldir, dldir is an absolute path.
#
# The response is a file to be generated by this script, and
#  must contain at least one of the following KV pairs:
#       productId=<eo-id>
#       url=<product-url>
#
# The response file is removed atomatically by the Ingestion
# Engine after processing it.
#
# The productId in the response file is the id of the newly
#  added product, the URL is where it can be accessed.
# The Ingestion Engine will read the response file once this
# script exits with a 0 status. An empty response file or no
# file is considered an error.
#
# A non-zero exit status indicates failure of the add product
# operation.
#

. "`dirname $0`/lib_common.sh"

info "Add product handler started ..."

#-----------------------------------------------------------------------------
# parse the CLI arguments
ACTION='ADD'

for _arg in $*
do
    _key="`expr "$_arg" : '\([^=]*\)'`"
    _val="`expr "$_arg" : '[^=]*=\(.*\)'`"

    case "$_key" in
        '-add' )
            ACTION="ADD" ; COLLECTION="$_val" ;;
        '-replace' )
            ACTION="REPLACE" ; IDENTIFIER="$_val" ;;
        '-id' )
            IDENTIFIER="$_val" ;;
        '-dldir' )
            DIR="$_val" ;;
        '-data' )
            DATA="$_val" ;;
        '-meta' | '-metadata' )
            META="$_val" ;;
        '-response' )
            RESPONSE="$_val" ;;
    esac
done

# check the CLI inputs
if [ -z "$ACTION" ] # no-action given error
then
    error "Missing mandatory '-add' or '--replace' action!" ; exit 1
fi

if [ "$ACTION" == "REPLACE" -a -z "$IDENTIFIER" ] # invalid replace action error
then
    error "REPLACE action requires the identifier!" ; exit 1
fi

if [ -n "$DATA" ] # no-data given
then
    if [ -n "$DIR" -a "${DATA:0:1}" != '/' ]
    then
        DATA="`expr "$DIR" : '\(.*[^/]\)'`/$DATA"
    fi
else
    error "Missing mandatory data ('-data') specification!" ; exit 1
fi

if [ -n "$META" ] # no-metadata given
then
    if [ -n "$DIR" -a "${META:0:1}" != '/' ]
    then
        META="`expr "$DIR" : '\(.*[^/]\)'`/$META"
    fi
fi

if [ -n "$RESPONSE" ] # no-response given
then
    if [ -n "$DIR" -a "${RESPONSE:0:1}" != '/' ]
    then
        RESPONSE="`expr "$DIR" : '\(.*[^/]\)'`/$RESPONSE"
    fi
fi

#-----------------------------------------------------------------------------
# following command executes the format detection, data preparation,
# and metadata extraction
. "`dirname $0`/products.d/detect.sh"

# get collection ID
_EOP20="http://www.opengis.net/eop/2.0"
_xq="//{$_EOP20}EarthObservationMetaData/{$_EOP20}parentIdentifier/text()"
[ -z "$COLLECTION" ] && COLLECTION="`xml_extract.py "$IMG_META" "$_xq"`"
[ -z "$COLLECTION" ] && COLLECTION="`jq -r '.["name"]' "$IMG_RTYPE" `"
[ -z "$COLLECTION" ] && { error "Failed to determine the target collection identifier!" ; exit 1 ; }

# get dataset ID
_xq="//{$_EOP20}EarthObservationMetaData/{$_EOP20}identifier/text()"
[ -z "$IDENTIFIER" ] && IDENTIFIER="`xml_extract.py "$IMG_META" "$_xq"`"
[ -z "$IDENTIFIER" ] && { error "Failed to determine the target dataset identifier!" ; exit 1 ; }

info "ACTION=$ACTION"
info "COLLECTION=$COLLECTION"
info "IDENTIFIER=$IDENTIFIER"
info "DIR=$DIR"
info "DATA=$DATA"
info "META=$META"
info "RESPONSE=$RESPONSE"
info
info "IMG_DIR=$IMG_DIR"
info "IMG_DATA=$IMG_DATA"
info "IMG_VIEW=$IMG_VIEW"
info "IMG_VIEW_OVR=$IMG_VIEW_OVR"
info "IMG_VIEW_RTYPE=$IMG_VIEW_RTYPE"
info "IMG_META=$IMG_META"
info "IMG_RTYPE=$IMG_RTYPE"

#-----------------------------------------------------------------------------
# EOxServer registration

#create time-series
if $EOXS_MNG eoxs_id_check --type DatasetSeries "$COLLECTION" 
then 
    $EOXS_MNG eoxs_collection_create --type DatasetSeries -i "$COLLECTION"
    $EOXS_MNG eoxs_metadata_set -i "$COLLECTION" -s 'wms_view' -l "${COLLECTION}_view"
    $EOXS_MNG eoxc_layer_create -i "$COLLECTION" --time
fi

if $EOXS_MNG eoxs_id_check --type DatasetSeries "${COLLECTION}_view"
then
    $EOXS_MNG eoxs_collection_create --type DatasetSeries -i "${COLLECTION}_view"
    $EOXS_MNG eoxs_metadata_set -i "${COLLECTION}_view" -s 'wms_alias' -l "$COLLECTION"
fi

# load range-type
$EOXS_MNG eoxs_rangetype_load -i "$IMG_RTYPE"

# register the data and view 
set -x 
$EOXS_MNG eoxs_id_check --type Coverage "$IDENTIFIER" || $EOXS_MNG eoxs_dataset_deregister "$IDENTIFIER"
$EOXS_MNG eoxs_id_check --type Coverage "${IDENTIFIER}_view" || $EOXS_MNG eoxs_dataset_deregister "${IDENTIFIER}_view"
$EOXS_MNG eoxs_dataset_register -r "`jq -r .name "$IMG_RTYPE"`" \
    -d "$IMG_DATA"  -m "$IMG_META" --collection "$COLLECTION" \
    --view "${IDENTIFIER}_view" $IMG_REG_OPT
$EOXS_MNG eoxs_dataset_register -r "$IMG_VIEW_RTYPE" -i "${IDENTIFIER}_view" \
    -d "$IMG_VIEW" -m "$IMG_META" --collection "${COLLECTION}_view" \
    --alias "$COLLECTION" 
# id2path file registry
{ 
    echo "#$IDENTIFIER"
    [ -n "$IMG_DIR" ] && echo "$IMG_DIR;directory"
    [ -n "$META" ] && echo "$META;metadata;"
    echo "$IMG_META;metadata;EOP2.0"
    echo "$IMG_DATA;data"
    echo "#${IDENTIFIER}_view"
    [ -n "$IMG_DIR" ] && echo "$IMG_DIR;directory"
    echo "$IMG_META;metadata;EOP2.0"
    echo "$IMG_VIEW;data;RGBA-WGS84"
} | $EOXS_MNG eoxs_i2p_load 

info "Add product handler finished sucessfully."
