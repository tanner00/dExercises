import std.stdio;
import std.typecons;

alias Pixel = Tuple!(ubyte, "r", ubyte, "g", ubyte, "b");

void writePPM(string name, Pixel[][] data)
{
	import std.file;
	import std.array : empty;

	assert(!data.empty);

	auto f = File(name ~ ".ppm", "w");

	f.writefln("P3\n%s %s\n255", data[0].length, data.length);

	f.writefln("%(%(%(%d %d %d %) %)\n%)", data);
}

void main(string[] args)
{
	assert(args.length == 2);

	import std.array : array;
	import std.conv : to;
	import std.random;
	import std.range : generate, take;

	// enum n = 500;
	auto n = to!int(args[1]);

	auto data = generate!(() => generate!(() => Pixel(uniform!ubyte, uniform!ubyte, uniform!ubyte))().take(n).array).take(n).array;

	writePPM("test", data);

}
