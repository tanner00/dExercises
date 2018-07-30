import std.algorithm;
import std.range;
import std.stdio;
import std.string;
import std.typecons;

import termbox;

// @todo: redraw paths to red
// @todo: COMMENT
// @todo: const correct

void main()
{

    void writeString(string s, int x, int y, Color fg = Color.basic)
    {
        foreach (i, c; s.enumerate(x))
        {
            setCell(i, y, c, fg, Color.basic);
        }
    }

    void zapLine(int line, int extent = width())
    {
        foreach (i; 0 .. extent)
        {
            setCell(i, line, ' ', Color.basic, Color.basic);
        }
    }

    void bresenhamLine(int x1, int y1, int x2, int y2, Color c = Color.basic)
    {
        int dx = x2 - x1;
        int dy = y2 - y1;

        int sx = dx > 0 ? 1 : -1;
        int sy = dy > 0 ? 1 : -1;

        import std.math : abs;

        dx = abs(dx);
        dy = abs(dy);
        int d = dx > dy ? dx : dy;

        double r = d / 2;

        int x = x1;
        int y = y1;
        if (dx > dy)
        {
            for (int i = 0; i < d; i++)
            {
                setCell(x, y, '-', c, Color.basic);
                x += sx;
                r += dy;
                if (r >= dx)
                {
                    y += sy;
                    r -= dx;
                }
            }
        }
        else
        {
            for (int i = 0; i < d; i++)
            {
                setCell(x, y, '-', c, Color.basic);
                y += sy;
                r += dx;
                if (r >= dy)
                {
                    x += sx;
                    r -= dy;
                }
            }
        }
    }

    auto dijkstra(int[][] graph, ulong source)
    {
        float[] dist;
        dist.length = graph.length;
        dist[] = float.infinity;
        dist[source] = 0;

        ulong[] prev;
        prev.length = graph.length;

        import std.container.rbtree;

        auto queue = redBlackTree!true([tuple(0, source)]);
        ulong[] visited;

        while (queue.length != 0)
        {
            Tuple!(int, ulong) u = queue.front;
            queue.removeFront();
            auto ud = u[0];
            auto ui = u[1];

            auto neighbors = graph[ui].enumerate.array.remove!(
                    a => a.value == 0 || visited.canFind(a.index));

            visited ~= u[1];

            foreach (v; neighbors)
            {
                auto relax = dist[ui] + v.value;
                if (dist[v.index] > relax)
                {
                    dist[v.index] = relax;
                    prev[v.index] = ui;
                }
                queue.insert(tuple(v.value, v.index));
            }

        }
        return tuple!("dist", "prev")(dist, prev);
    }

    enum Mode : ubyte
    {
        add,
        connect,
        setWeight,
        pathing,
    }

    init();

    setInputMode(InputMode.esc | InputMode.mouse);

    auto currentMode = Mode.add;

    auto writeModeString = () => {
        zapLine(0);
        writeString("Mode: %s  [CtrlA: %s mode, CtrlC: %s mode, CtrlP: %s mode, CtrlE: erase]"
                .format(currentMode, Mode.add, Mode.connect, Mode.pathing), 0, 0);
    }();

    writeModeString();

    auto nodeChar = 'a';

    alias LogicalNode = Tuple!(int, "x", int, "y", char, "id");
    alias Connection = Tuple!(LogicalNode, "from", LogicalNode, "to", int, "w");

    Connection[] connections;
    LogicalNode[] nodes;
    Event e;
    do
    {
        flush();
        pollEvent(&e);

        if (e.key == Key.ctrlA)
        {
            currentMode = Mode.add;
            writeModeString();
        }
        else if (e.key == Key.ctrlC)
        {
            currentMode = Mode.connect;
            writeModeString();
        }
        else if (e.key == Key.ctrlP)
        {
            currentMode = Mode.pathing;
            writeModeString();
        }
        else if (e.key == Key.ctrlE)
        {
            clear();

            nodes.destroy();
            connections.destroy();
            nodeChar = 'a';

            currentMode = Mode.add;
            writeModeString();
        }

        static int xmid, ymid;
        final switch (currentMode)
        {
        case Mode.add:

            if (e.key == Key.mouseLeft && e.y > 0 && nodeChar <= 'z')
            {
                nodes ~= LogicalNode(e.x, e.y, nodeChar);
                setCell(e.x, e.y, nodeChar, Color.basic, Color.basic);
                ++nodeChar;
            }

            break;
        case Mode.connect:

            static int xlast, ylast;
            if (e.key == Key.mouseLeft)
            {
                if (xlast == 0)
                {
                    xlast = e.x;
                    ylast = e.y;
                }
                else
                {
                    scope (exit)
                        xlast = 0, ylast = 0;

                    auto screenMatch = (LogicalNode a, Tuple!(int, int) b) => a
                        .x == b[0] && a.y == b[1];

                    // D should have an Option type.
                    auto maybe1 = nodes.find!(screenMatch)(tuple(xlast, ylast));
                    auto maybe2 = nodes.find!(screenMatch)(tuple(e.x, e.y));
                    if (maybe1.empty || maybe2.empty)
                        break;
                    auto at1 = maybe1[0];
                    auto at2 = maybe2[0];

                    if (at1 == at2)
                        break;

                    auto connectionMatch = (Connection a, Connection b) => a
                        .from == b.from && a.to == b.to;

                    auto c = Connection(at1, at2, 0);
                    // No existing connections
                    if (connections.canFind!(connectionMatch)(c)
                            || connections.canFind!(connectionMatch)(Connection(at2,
                                at1, 0)))
                        break;

                    connections ~= c;
                    bresenhamLine(xlast, ylast, e.x, e.y, Color.red);
                    setCell(at1.x, at1.y, at1.id, Color.basic, Color.basic);

                    currentMode = Mode.setWeight;
                    xmid = (e.x + xlast) / 2;
                    ymid = (e.y + ylast) / 2;
                }
            }

            break;
        case Mode.setWeight:
            zapLine(height() - 1);
            enum request = "Pick Weight: % (%s %)".format(iota(1, 10));
            writeString(request, 0, height() - 1);

            // if (e.key == Key.mouseLeft)
            // {
            // const auto w = 9 - (cast(int) request.length - cast(int) e.x) / 2;
            import std.random : uniform;

            const auto w = uniform(1, 10);
            connections.back.w = w;

            writeString("%s".format(w), xmid, ymid);
            zapLine(height() - 1);
            currentMode = Mode.connect;
            // }

            break;
        case Mode.pathing:

            immutable charToId = (char a) => a - 'a';

            int[][] adjm;
            adjm.length = charToId(nodeChar);
            foreach (ref r; adjm)
            {
                r.length = charToId(nodeChar);
            }

            foreach (i, c; connections)
            {
                auto to = charToId(c.to.id);
                auto from = charToId(c.from.id);

                adjm[from][to] = c.w;
                adjm[to][from] = c.w;
            }

            immutable auto idToChar = (ulong a) => cast(char)(a + 'a');

            immutable auto requestStr = (string s) => "Pick %s: % (%c %)"
                .format(s, iota(0, charToId(nodeChar)).map!(idToChar));

            immutable auto xOffsetToId = (string request, ulong x) => (charToId(nodeChar) - 1) - (
                    request.length - x) / 2;

            static auto gettingSource = true;
            static ulong source, sink;
            import std.traits : ReturnType;

            static ReturnType!dijkstra path;

            final switch (gettingSource)
            {
            case true:

                zapLine(height() - 1);
                auto requestSource = requestStr("Source");
                writeString(requestSource, 0, height() - 1);

                if (e.key == Key.mouseLeft && e.y == height() - 1)
                {
                    // @todo: could redraw here

                    source = xOffsetToId(requestSource, e.x);
                    if (source < 0 || source > nodeChar)
                        break;

                    gettingSource = false;
                }

                break;
            case false:
                zapLine(height() - 1);
                auto requestSink = requestStr("Sink");
                writeString(requestSink, 0, height() - 1);

                if (e.key == Key.mouseLeft && e.y == height() - 1)
                {
                    sink = xOffsetToId(requestSink, e.x);
                    if (sink < 0 || sink > nodeChar)
                        break;

                    path = dijkstra(adjm, source);
                    scope (exit)
                        gettingSource = true;

                    if (path.dist[sink] == float.infinity)
                        break;

                    do
                    {
                        auto to = nodes[sink];
                        auto from = nodes[path.prev[sink]];

                        bresenhamLine(to.x, to.y, from.x, from.y, Color.green);

                        auto w = connections.find!((a, b) => (a.from == b.from
                                || a.to == b.from) && (a.from == b.to || a.to == b
                                .to))(Connection(to, from, 0))[0].w + '0';

                        // redraw the weights
                        setCell((to.x + from.x) / 2, (to.y + from.y) / 2, w,
                                Color.basic, Color.basic);

                        // redraw the ids
                        setCell(to.x, to.y, to.id, Color.basic, Color.basic);
                        setCell(from.x, from.y, from.id, Color.basic, Color.basic);

                        sink = path.prev[sink];
                    }
                    while (sink != source);
                }

                break;
            }
            break;
        }
    }
    while (e.key != Key.esc);

    shutdown();

}
