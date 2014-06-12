#!/bin/sh
#
#  AddProduct action handler.
#
# USAGE: 
#  product_add.sh [-replace=<existing_prod_id> | -add[=<collection>] ]
#    -dldir=<download_directory> -response=<filename>
#    -data=<datafile> -meta=<metadatafile>
#
# PARAMETERS: 
#
#   -add[=<collection>] Indicates that a new product shall be
#                       registered. Optionally, collection to
#                       which the product shall be inserted 
#                       can be specified.
#
#   -replace=<prod_id>  Indicates the an existing product 
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

info "Add product hadler started ..."
info "   ARGUMENTS: $* "

error "NOT IMPLEMENTED!" ; exit 1 