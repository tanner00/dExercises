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

    enum t = 10;
    foreach (i; 0 .. t)
    {
        auto n = uniform(1, 50_000_000);
        enum cut = 5;

        auto values = randInts(n);
        int[] buckets;
        buckets.length = 1000;

        // Traverse into the middle of the data stream for fun.
        auto testCase = values.drop(n / cut).takeExactly(n / cut);
        foreach (v; testCase)
        {
            auto bn = v.hashOf % buckets.length;
            buckets[bn] = max(buckets[bn], v.bsf);
        }

		import std.math : log2, pow;
        auto est = 2 ^^ (cast(double) buckets.sum / buckets.length) * buckets
            .length * 0.79402 * cut;

		auto e = est / n;
        writefln("Exact: %s\tEst: %d\tError: %s", n, cast(int) est, e);
    }
}
