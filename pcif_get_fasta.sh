#!/bin/sh
# pCIF - parsable CIF.
# See the LICENSE file for binding license information.
# Copyright (C) 2015 Yuval Sedan

# Usage: cat *.pcif | pcif_get_fasta.sh
#
# Extracts a FASTA format file from a pCIF file.
# If multiple pCIF inputs are concatenated, a multi-sequence FASTA file results.

$(dirname $(readlink -f $0))/pcif_query.sh \
	_entity_poly.pdbx_strand_id.type.pdbx_seq_one_letter_code_can | \
	$(dirname $(readlink -f $0))/pcif_tsv.sh | \
	mawk -F'\t' '
		!/^#/ {
			pdb_id=$1; strand=$2; poly_type=$3; seq=$4;
			print ">" pdb_id "|" strand "|" poly_type;
			print seq;
		}
	'
