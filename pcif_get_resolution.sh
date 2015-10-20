#!/bin/sh
# pCIF - parsable CIF.
# See the LICENSE file for binding license information.
# Copyright (C) 2015 Yuval Sedan

# Usage: cat *.pcif | pcif_get_resolution.sh
#
# Reads information about the structure's experimental method and resolution
# and outputs a table with this information. This is similar to the one provided by the
# PDB's resolu.idx.

$(dirname $(readlink -f $0))/pcif_query.sh \
	_exptl.method \
	_em_3d_reconstruction.method.resolution \
	_refine.pdbx_refine_id.ls_d_res_high | \
	awk -F'\t' -v 'OFS=\t' '
		BEGIN {
			method_translate["ELECTRON CRYSTALLOGRAPHY"] = "ELECTRON MICROSCOPY"; # some 50 PDBs have this
			method_translate["Fiber-diffraction"] = "FIBER DIFFRACTION"; # PDB ID 2zwh has this anomaly - mentioned this to RCSB; they said it would be fixed by the end of the year
			method_translate["CRYO-ELECTRON MICROSCOPY"] = "ELECTRON MICROSCOPY"; # obsolete PDB ID 1GR6
			method_translate["ELECTRON DIFFRACTION"] = "ELECTRON MICROSCOPY"; # obsolete PDB ID 1HW0
			method_translate["SYNCHROTRON X-RAY DIFFRACTION"] = "X-RAY DIFFRACTION"; # obsolete PDB ID 1RMI
			method_translate["X-RAY DIFFRACTION, MOLECULAR REPLACEMENT"] = "X-RAY DIFFRACTION"; # obsolete PDB ID 1DH2
		}
		function normalize_method(method,        renamed_method) {
			renamed_method = method_translate[method];
			method = (renamed_method? renamed_method : method);
			# the following fixes annotation on some OBSOLETE entries, e.g. 1SIA
			if (method ~ /^NMR,/) { method = "NMR"; }
			return method;
		}
		function fix_missing_pdbx_refine_id() {
			# this happens for SOME 765 OBSOLETE entries, e.g. 1OAM
			# in this case, where _refine.pdbx_refine_id is missing,
			# the pcif_query.sh script will place a pound side (#)
			# in that column, so we would have res["#"]=resolution and
			# res["SOME METHOD"]="#"
			if (!("#" in res)) {
				return;
			}
			method = method_by_ordinal[1];
			if ( res[method] == "#" ) {
				res[method] = res["#"];
				delete res["#"];
			}
			else {
				print "Error: _refine.pdbx_refine_id is missing but somehow some method did get a res record?! In file " file > "/dev/stderr";
			}
		}
		function fix_4xpt() {
			# 4xpt has under _refine_id.pdbx_refine_id the number 1 rather than the _exptl.method name
			# I assumed this was because they thought they should give the experimental method ordinal number
			# by this logic, I apply the following fix
			# I mentioned this to RCSB and they said it would be fixed by the end of the year.
			for (method in res) {
				if (int(method)==method) {
					if (res[method]*1.0>0) {
						# only use this record if it carries information
						res[method_by_ordinal[method]] = res[method];
					}
					delete res[method];
				}
			}
		}
		function end_file() {
			if (!file) { return; }
			fix_4xpt();
			fix_missing_pdbx_refine_id();
			for (method in res) {
				print file,method,res[method];
			}
			delete res;
			delete method_by_ordinal;
			n_methods=0;
		}
		/^>/ {
			end_file();
			file=substr($1,2);
		}
		/^#/ { category=$1; }
		/^\t/{
			if (category=="#_refine") {
				method=normalize_method($2);
				res[method]=$3;
			}
			else if (category=="#_exptl") {
				method=normalize_method($2);
				n_methods++;
				method_by_ordinal[n_methods]=method; # see fix_4xpt
				if (!(method in res)) {
					res[method] = "#";
				}
			}
			else if (category=="#_em_3d_reconstruction") {
				#method=$2 " ELECTRON MICROSCOPY";
				#delete res["ELECTRON MICROSCOPY"];
				method=normalize_method("ELECTRON MICROSCOPY");
				res[method]=$3;
			}
		}
		END { end_file(); }
	'
