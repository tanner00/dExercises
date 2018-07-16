import std.stdio;
import std.algorithm.iteration : map;

// Tested on some ELF files in anu/build

void main(string[] args)
{
	assert(args.length == 2, "Please supply a filename to read");

	auto f = File(args[1]);
	scope(exit) f.close();

	const read_size = 0x10;
	
	auto n = 0;
	foreach (ubyte[] line; f.byChunk(read_size)) {
		auto text_repr = line.map!(c =>
					   c > '~' || c < ' ' ? '.' : char(c));

		// The hard bits of this format string is from dlang.org landing page.
		// They seem quite powerful in D.
		// The number 3 is used in 3 * (read_size) - line.length because
		// each printed byte int hex including the space will be of length 3.
		writefln!("%08x: %(%02x %)%*s  %s")(n, line, 3 *
						   (read_size - line.length), "", text_repr);
		
	        n += read_size;
	}
	
}
