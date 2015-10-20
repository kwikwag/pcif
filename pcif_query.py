#!/usr/bin/env python
# pCIF - parsable CIF.
# See the LICENSE file for binding license information.
# Copyright (C) 2015 Yuval Sedan

# This was meant to be an implementation of pcif_query.py in Python.
# But it is not complete. Use pcif_query.sh.

from __future__ import print_function
import sys
import operator

query = {}
for arg in sys.argv[1:]:
	period_index = arg.find('.')
	if (period_index == -1):
		category = arg
		fields = None
	else:
		category = arg[0:period_index]
		fields = arg[period_index+1:].split('.')
	query[category] = fields

print(query)

display = False
for line in sys.stdin:
	if line.startswith('>'):
		print(line.strip())
		display = False
	elif line.startswith('#'):
		cols = line.strip().split('\t')
		category = cols[0][1:]
		query_columns = query.get(category, False)
		display = False
		if query_columns == False:
			pass
		else:
			display = True
			if query_columns == None:
				column_getter = None
			else:
				column_index_map = { header: index for index, header in enumerate(cols[1:], 1) }
				column_getter = operator.itemgetter(*( column_index_map.get(column_name, -1) for column_name in query_columns ))
	if display == True:
		if column_getter == None:
			print(line.strip())
		else:
			# note that we expect .strip() to strip not only the newline at the
			# end of the line, but the preceding tab character
			cols = line.strip().split("\t")
			if (line.startswith('#')):
				print(cols[0] + "\t", end="")
			else:
				print("\t", end="")
			# TODO : what to do with column_getter -1 indices (missing values)
			print(*column_getter(cols), sep="\t")
