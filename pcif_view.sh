#!/bin/sh
# pCIF - parsable CIF.
# See the LICENSE file for binding license information.
# Copyright (C) 2015 Yuval Sedan

# Usage: pcif_view.sh <pdb_id>
#
# Retrieves a mmCIF file by its PDB ID from the PDB databases, and uses tabview
# to view it in its pCIF format.
# Requires tabview in PATH. See https://github.com/firecat53/tabview

$(dirname $(readlink -f $0))/pcif_fetch.sh "$@" | tabview -d$'\t' -
