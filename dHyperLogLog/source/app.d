void main()
{

    import core.bitop : bsf;
    import std.algorithm.comparison : max;
    import std.algorithm.iteration : sum;
    import std.random : uniform;
    import std.range : iota, takeExactly, drop;
    import std.stdio;

    auto randInts(int a)
    {
        int[] vs;
        vs.length = a;
        foreach (ref v; vs)
        {
            v = uniform(int.min, int.max);
        }
        return vs;
    }

    enum t = 25;
    float avgError = 0;
    foreach (i; 0 .. t)
    {
        auto n = uniform(1, 8000000);
        auto cut = 10;

        auto values = randInts(n);
        int[] buckets;
        buckets.length = 1536 / 4; // 1.5 KiB

        import std.math : log2, pow;

		// Traverse into the middle of the data stream for fun.
		auto testCase = values.drop(cast(int) n.log2).takeExactly(n / cut);
        foreach (v; testCase)
        {
            auto bn = v.hashOf % buckets.length;
            buckets[bn] = max(buckets[bn], v.bsf);
        }

        auto est = 2 ^^ (cast(double) buckets.sum / buckets.length) * buckets
            .length * 0.79402 * cut;
        // writefln("Exact: %s | Est: %d", n, cast(int) est);
        // writeln("Error: ", n / est);
        avgError += n / est;
    }
    writefln("%.3f", avgError / t);
}
