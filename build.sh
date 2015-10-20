#!/bin/sh
# pCIF - parsable CIF.
# See the LICENSE file for binding license information.
# Copyright (C) 2015 Yuval Sedan

# Usage: CCTBX_HOME=/path/to/cctbx build.sh CPP_FILE COMPILER_FLAGS
#
# Builds an executable linked to CCTBX UCIF.
# Useful for compiling CIF parsers using the UCIF code.
#
# Requires a built copy of teh CCTBX project. The CCTBX_HOME environment
# variable should point to a location which has the cctbx_source and
# cctbx_build subdirectories.

cctbx_src=${CCTBX_HOME}/cctbx_sources
cctbx_bld=${CCTBX_HOME}/cctbx_build
prog="$(basename $1 .cpp).cpp"
shift

g++ "$@" -std=c++11 \
	-I ${cctbx_src}/ucif/antlr3/include \
	-I ${cctbx_src}/ucif/antlr3 \
	-I ${cctbx_src} \
	-L${cctbx_bld}/ucif \
	-L${cctbx_bld}/ucif/antlr3/src \
	${cctbx_bld}/ucif/cifParser.o \
	${cctbx_bld}/ucif/cifLexer.o \
	${cctbx_bld}/ucif/antlr3/src/antlr3*.o \
	-o $(basename ${prog} .cpp) ${prog}
