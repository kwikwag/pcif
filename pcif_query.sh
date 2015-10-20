#!/bin/sh
# pCIF - parsable CIF.
# See the LICENSE file for binding license information.
# Copyright (C) 2015 Yuval Sedan

# Usage: pcif_query.sh [QUERY ...]
#
# Retrieves a subset of the pCIF file according to the QUERY.
#
# QUERY is either a category name (e.g. `_atom_site`) or a category
# name followed by a list of entries, delimited by periods (e.g.
# `_atom_site.Cartn_x.Cartn_y.Cartn_z`.
#
# The scripts filters information from the pCIF file so that only
# categories that appear in some QUERY are output. If the QUERY specifies
# entries, only those entries are output, and other columns are filtered out.

missing_value_token="#"
query_cats="$@"
query_cats=${query_cats// /,}
mawk -F'\t' -v 'OFS=\t' -v "MISSING_VALUE=${missing_value_token}" -v "query_cats=${query_cats}" '
	BEGIN {

		n_cats=split(query_cats, cat_arr, ",");
		for (cat_num in cat_arr) {
			query=cat_arr[cat_num];
			first_period=index(query, ".");

			if (first_period>0) {
				cat=substr(query,1,first_period-1);
				n_cols = split(substr(query, first_period+1), query_cat_cols, ".");
				cat_cols[cat_num,"n"]=n_cols;
				for (col_num=1; col_num<=n_cols; ++col_num) {
					cat_cols[cat_num,col_num]=query_cat_cols[col_num];
				}
			}
			else {
				cat=query;
				cat_cols[cat_num,"n"]=0;
			}
			cat_map[cat]=cat_num;
		}
		cat_num="";
	}
	/^#/ { cat = substr($1,2);
		cat_num = cat_map[cat];
		if (cat_num) {
			n_cols=cat_cols[cat_num,"n"];
			if (n_cols == 0) {
				# show all columns
				show_all_cols=1;
			}
			else {
				show_all_cols=0;
				delete col_indices;
				for (i=2; i<=NF; ++i) {
					col_indices[$i] = i;
				}
				delete show_col_indices;
				for (col_num=1; col_num<=n_cols; ++col_num) {
					show_col_indices[col_num]=col_indices[cat_cols[cat_num,col_num]];
				}
			}
		}
	}
	/^>/ { print; cat_num=0; }
	cat_num {
		if (show_all_cols == 1) {
			print;
		}
		else {
			# header lines preceded with header
			if (/^#/) {
				printf("%s\t", $1);
			}
			else {
				printf("\t");
			}
			for (col_num=1; col_num<=n_cols; ++col_num) {
				if (col_num>1) { printf(OFS); }
				col_index=show_col_indices[col_num];
				printf("%s", col_index? $col_index : MISSING_VALUE);
			}
			printf("\n");
		}
	}
'
