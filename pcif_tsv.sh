#!/bin/sh
# pCIF - parsable CIF.
# See the LICENSE file for binding license information.
# Copyright (C) 2015 Yuval Sedan

# Usage: cat *.pcif | pcif_tsv.sh
#
# Reformats the pCIF file so that it looks like a tab-separated file, which
# may be read by spreadsheet software or other scripts. The ID of the entry
# (e.g. PDB ID) is appended in each line, and entry named are made unique
# by bringing together the category and entry name together again (as in the
# mmCIF original).

awk -v 'OFS=\t' '
	/^>/ { file=substr($0,2); }
	/^#/ {
		category = substr($1, 2);
		$1 = "#id";
		for (i=2; i<=NF; ++i) {
			$i = category "." $i;
		}
		print;
	}
	/^\t/ {
		print file $0;
	}
'
