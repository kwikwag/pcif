// pCIF - parsable CIF.
// See the LICENSE file for binding license information.
// Copyright (C) 2015 Yuval Sedan

#include <fstream>
#include <iostream>
#include <vector>
#include <unordered_set>
#include <ucif/parser.h>
#include <ucif/builder.h>
#include <regex>
#include <cassert>

namespace ucif { namespace example {

struct vector_array_wrapper : array_wrapper_base
{
	std::vector<std::string> array;

	vector_array_wrapper()
	: array()
	{}

	virtual ~vector_array_wrapper() {
		array.clear();
	}

	virtual void push_back(std::string const& value)
	{
		array.push_back(value);
	}

	virtual std::string operator[](unsigned const& i) const
	{
		return array[i];
	}

	virtual unsigned size() const
	{
		return array.size();
	}
};

template<typename T> T lowercase(T s) {
	std::transform(s.begin(), s.end(), s.begin(), ::tolower);
	return s;
}

// In a notion somewhat similar to how SAX works for XML, the builder's methods
// get called every time a new entity is encountered in the CIF file.
// This builder implementation simply reformats (hence the name) the contents into
// the pCIF format.
struct reformatter : builder_base
{
	std::regex newline;
	std::regex whitespace;
	std::stringstream category_headers;
	std::stringstream category_values;
	std::string last_category;
	bool record_mode;

	reformatter() : whitespace("\\s+"), newline("[\\n\\r]"), last_category(""), record_mode(false) {
	}

	std::string normalize_value(std::string const & value) {
		return std::regex_replace(std::regex_replace(value, newline, ""), whitespace, " ");
	}
	void flush_category() {
		// assume record_mode=true
		std::string headers = category_headers.str();
		std::string values = category_values.str();
		category_headers.str("");
		category_values.str("");
		last_category = "";
		std::cout << headers << std::endl << values << std::endl;
		record_mode = false;
	}
	virtual void start_save_frame(std::string const& save_frame_heading) {
		if (record_mode) {
			flush_category();
		}
		std::cout << "^" << save_frame_heading << std::endl;
	}
	virtual void end_save_frame() {
		if (record_mode) {
			flush_category();
		}
		std::cout << "$" << std::endl;
	}
	virtual void add_data_item(std::string const& tag, std::string const& value) {
		size_t period_index = tag.find('.', 0);
		std::string this_category = tag.substr(0, period_index);
		std::string this_key = tag.substr(period_index+1);
		if ( this_category != last_category ) {
			if ( record_mode ) {
				flush_category();
			}
			last_category = this_category;
		}
		if (record_mode) {
			category_headers << "\t";
			category_values << "\t";
		}
		else {
			category_headers << "#" << this_category << "\t";
			category_values << "\t";
		}
		category_headers << this_key;
		category_values << normalize_value(value);
		record_mode = true;
	}
	virtual void add_loop(array_wrapper_base const& loop_headers,
												std::vector<array_wrapper_base*> const& values) {
		if (record_mode) {
			flush_category();
		}
		int col_count = loop_headers.size();
		assert(col_count>0);
		size_t period_index=loop_headers[0].find('.', 0);
		std::string category = loop_headers[0].substr(0, period_index);
		for (int i=0; i<col_count; ++i) {
			if (loop_headers[i].compare(0, period_index, category) != 0) {
				std::cerr << "Error: loop contained mixed categories " << loop_headers[i] << " and " << loop_headers[0] << "." << std::endl;
				exit(1);
			}
			if (i>0) { std::cout<<"\t"; }
			else { std::cout << "#" << category << "\t"; }
			std::cout << loop_headers[i].substr(period_index+1);
		}
		std::cout<<std::endl;

		int row_count = values[0]->size();
		for (int row=0; row < row_count; ++row) {
			for (int i=0; i < col_count; ++i) {
				std::cout << "\t";
				array_wrapper_base *col_vals=values[i];
				std::cout << normalize_value( (*col_vals)[row] );
			}
			std::cout << std::endl;
		}
	}
	virtual void add_data_block(std::string const& data_block_heading) {
		if (record_mode) {
			flush_category();
		}
		assert(data_block_heading.compare(0, 5, "data_")==0);
		std::cout << ">" << data_block_heading.substr(5) << std::endl;
	}
	void end_file() {
		if (record_mode) {
			flush_category();
		}

	}
	virtual array_wrapper_base* new_array()
	{
		return new vector_array_wrapper();
	}
};

}} // namespace ucif::example

namespace ucif {

// This is practically a copy+paste of code found in the ucif/ directory of the cctbx project.
// I figured there should be a class to handle streams in general, but I didn't really figure
// out how the code by ANTLR3 works that way. In addition, the antlr3FileStreamNew seemed to
// have problems with things that aren't actually disk files (e.g. pipes).
// So right now it does what the cctbx example code does - reads the entire file into an
// in-memory string, using ifstream. This works, and it works quickly enough.
class CifFileParser {
	private:
		CifFileParser(const CifFileParser &);
		const CifFileParser& operator=(const CifFileParser &);
	public:
		CifFileParser() {}
		CifFileParser( builder_base* builder, std::string const filename, bool const strict=true) {
			// antlr3FileStreamNew doesn't know how to eat pipes properly, so I didn't use it evetually
			// input = antlr3FileStreamNew(pANTLR3_UINT8(filename.c_str()), ANTLR3_ENC_8BIT);
			std::stringstream data;
			std::ifstream myfile(filename, std::ifstream::in);
			if (!myfile.is_open()) {
				std::cerr << "Error: could not open file " << filename << std::endl;
				exit(1);
			}
			char * buf = new char[1024*1024+1];

			while (true) {
				myfile.read(buf, 1024*1024);
				int bytes_read = myfile.gcount();
				buf[bytes_read]='\0'; // null-terminate
				data << buf;
				if ( bytes_read < 1024*1024 ) {
					break;
				}
			}

			delete buf;

			myfile.close();

			// see http://stackoverflow.com/questions/1374468/stringstream-string-and-char-conversion-confusion
			std::string const & data_string = data.str();
			data.clear();

				input = antlr3StringStreamNew(
				pANTLR3_UINT8(data_string.c_str()),
				ANTLR3_ENC_8BIT,
				data_string.size(),
				pANTLR3_UINT8(filename.c_str())
			);

			lxr = cifLexerNew(input);
			tstream = antlr3CommonTokenStreamSourceNew(ANTLR3_SIZE_HINT, TOKENSOURCE(lxr));
			psr = cifParserNew(tstream);
			psr->pParser->rec->displayRecognitionError = parser_displayRecognitionError;
			psr->errors = builder->new_array();
			lxr->pLexer->rec->displayRecognitionError = lexer_displayRecognitionError;
			lxr->errors = builder->new_array();
			psr->parse(psr, builder, strict);
			fflush(stderr);
		}
		~CifFileParser() {
			delete psr->errors;
			delete lxr->errors;
			psr->free(psr);
			tstream->free(tstream);
			lxr->free(lxr);
			input->close(input);
		}

		pcifLexer lxr;
		pcifParser psr;

	private:
		pANTLR3_COMMON_TOKEN_STREAM tstream;
		pANTLR3_INPUT_STREAM input;

};
} // namespace ucif

void usage() {
		std::cerr << "Usage: cif_query FILE QUERY [...]" << std::endl;
}

// Again, the program is essentially a copy of the cctbx code from the ucif/ directory.
// The main logic of this program lies in the reformatter class.
int main (int argc, char *argv[])
{
	// very naive argument parser
	std::string filename;
	if (argc>1) {
		filename = std::string(argv[1]);
		if (filename == "-") { filename = "/dev/stdin"; }
	}
	else {
		filename = "/dev/stdin";
	}

	ucif::example::reformatter builder;
	ucif::CifFileParser ucif_parser(&builder, filename, /*strict=*/true);
	builder.end_file();

	// Were there any lexing/parsing errors?
	std::vector<std::string> lexer_errors =
		dynamic_cast<ucif::example::vector_array_wrapper*>(ucif_parser.lxr->errors)->array;
	std::vector<std::string> parser_errors =
		dynamic_cast<ucif::example::vector_array_wrapper*>(ucif_parser.psr->errors)->array;
	for (int i=0;i<lexer_errors.size();i++) {
		std::cerr << "Lexer error: " << lexer_errors[i] << std::endl;
	}
	for (int i=0;i<parser_errors.size();i++) {
		std::cerr << "Parser error: " << parser_errors[i] << std::endl;
	}
	if (lexer_errors.size() + parser_errors.size() != 0) {
		return 1;
	}
	return 0;
}

