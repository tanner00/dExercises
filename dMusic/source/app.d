import std.algorithm;
import std.file;
import std.path;
import std.random;
import std.range;
import std.string;
import std.typecons;

import derelict.sfml2.system;
import derelict.sfml2.audio;
import termbox;

void main(string[] args)
{
    void writeString(string s, int x, int y, Color fg = Color.basic)
    {
        foreach (i, c; s.enumerate(x))
        {
            setCell(i, y, c, fg, Color.basic);
        }
    }

    void zapLine(int line)
    {
        foreach (i; 0 .. width)
        {
            setCell(i, line, ' ', Color.basic, Color.basic);
        }
    }

    // Documentation of core.time states that it offers no
    // format string facilities
    string formatTime(float seconds)
    {
        return format!"%02d:%02d"(cast(int) seconds / 60, cast(int) seconds % 60);
    }

    Tuple!(sfMusic*, "music", string, "duration") getSong(DirEntry[] musicDir)
    {
        auto songPath = musicDir.choice;

        zapLine(0);
        writeString("Playing " ~ songPath.baseName.stripExtension, 0, 0, Color
                .green);

        sfMusic* newSong = sfMusic_createFromFile(songPath.toStringz);

        return typeof(return)(newSong, formatTime(newSong.sfMusic_getDuration
                .sfTime_asSeconds));
    }

    assert(args.length == 2, "Please supply a directory of music to shuffle");

    init();
    scope (exit)
        shutdown();

    setInputMode(InputMode.esc);

    DerelictSFML2System.load();
    DerelictSFML2Audio.load();

    // @note: SFML purportedly supports ogg, wav (only PCM), and flac files
    // @note: I have only tested a few types of each
    auto musicDir = dirEntries(args[1], "*.{ogg,wav,flac}", SpanMode.shallow)
        .filter!(isFile).array;

    auto song = getSong(musicDir);
    sfMusic* currentSong = song.music;
    string songDuration = song.duration;
    scope (exit)
        sfMusic_destroy(currentSong);

    sfMusic_play(currentSong);

    Event e;
    do
    {
        if (sfMusic_getStatus(currentSong) == sfStopped || e.key == Key.ctrlS)
        {
            sfMusic_destroy(currentSong);

            song = getSong(musicDir);
            currentSong = song.music;
            songDuration = song.duration;

            sfMusic_play(currentSong);
        }
        auto completedTime = formatTime(currentSong.sfMusic_getPlayingOffset
                .sfTime_asSeconds);

        zapLine(1);
        writeString(completedTime ~ " / " ~ songDuration, 0, 1, Color.red);

        flush();
        peekEvent(&e, 100);
    }
    while (e.key != Key.esc);

}
