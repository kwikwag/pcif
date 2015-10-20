# pCIF - Parsable CIF

This is a test project on handling PDBx/mmCIF files.

## The pCIF format

The mmCIF format, based on CIF, itself based on STAR, is rather complex to parse using Linux command-line tools.

Using CCTBX it's easy to build a CIF parser in C++. So I did that to produce what I call the pCIF format (or parsable CIF).
It has simple parsing rules: each type of data begins with a certain character at the beginning of the line.

  Line begins with       | For
  -------------------------------------------------------------
  `!data_`               | data segment start
  `#_`                   | table (loop) start
  `\t` (tab character)   | table data
  `^`                    | save frame start (not used in mmCIF)
  `$`                    | save frame end (not used in mmCIF)

Data in tables is tab-delimited. Values that had newlines in mmCIF are stripped of them,
and any sequence of whitespace in mmCIF is converted to a single space character (' ') here.

## Scripts

Each script has a usage comment inside. Most of the scripts use `awk` (some specifically
reference `mawk` for speed).

The `tabview` program is highly recommended for viewing tab-delimited files (pCIF, for
example). See https://github.com/firecat53/tabview for details.

## License

See the LICENSE file for binding license information.
Copyright (C) 2015 Yuval Sedan
