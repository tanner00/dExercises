import std.conv;
import std.file;
import std.range : enumerate;
import std.regex;
import std.stdio;

import colorize : color, cwriteln, cwritef, fg;

// G/re/p supported by Dlang regexes.
// Example: ./dgrep source/app.d "(if|foreach)"

// @todo: add switch for non-matching lines.
// @todo: add more general pipes

void main(string[] args)
{
	assert(args.length == 3, "Please supply a filename and regex");

        auto haystack = File(args[1]);
        auto needle = regex(args[2], "m");
	
	foreach (i, l; haystack.byLine.enumerate(1)) {
		auto m = matchFirst(l, needle);
		if (m.length == 0) continue;
		
		cwritef("%03d: ".color(fg.yellow), i);
		cwriteln(to!string(l).color(fg.light_green));
	}
}
