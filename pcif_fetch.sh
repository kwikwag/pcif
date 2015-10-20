#!/bin/sh
# pCIF - parsable CIF.
# See the LICENSE file for binding license information.
# Copyright (C) 2015 Yuval Sedan

# Usage: pcif_fetch.sh <pdb_id>
#
# Retrieves a mmCIF file by its PDB ID from the PDB databases and converts it into pCIF format on-the-fly

pdb_id=$1
file=${PDB_HOME}/mmCIF/${pdb_id:1:2}/${pdb_id}.cif.gz
! [ -f ${file} ] && file=${file/pdb/pdb/obsolete} && echo "Warning: viewing an obsolete entry!" > /dev/stderr
zcat ${file} | $(dirname $(readlink -f $0))/pcif
