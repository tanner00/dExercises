import std.stdio;

enum MapType
{
    bit,
    gray,
    pix,
}

void writePPM(string name, ubyte[][] data, MapType mtype)
{
    import std.file;
    import std.conv : to;
    import std.array : empty;

    assert(!data.empty);

    auto f = File(name, "w");
    f.writefln("P%s", to!int(mtype + 1));

    if (mtype == MapType.pix)
        f.writefln("%s %s", data[0].length / 3, data.length / 3);
    else
        f.writefln("%s %s", data[0].length, data.length);

    foreach (i; 0 .. data.length)
    {
        f.writefln("%(%s %)", data[i]);
    }
}

void main()
{

    import std.array : array;
    import std.random : uniform;
    import std.range : generate, take;

    enum n = 3 * 256;

    ubyte[][] data = generate!(() => generate!(() => uniform!ubyte)().take(n)
            .array).take(n).array;

    writePPM("test.pgm", data, MapType.gray);

}
