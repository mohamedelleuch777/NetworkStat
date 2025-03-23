import std.stdio;
import std.range;
import std.getopt;
import std.string;
import std.conv;
import std.array;
import std.file;
import std.datetime;
import core.thread;
import std.algorithm;
import std.process : execute;
import std.string : split, strip;
import std.file : readText;
import std.string : split, strip, splitLines;
import std.process : execute;
import std.conv : to;

enum VERSION = "1.4.1";
enum DEFAULT_SLEEP = 1;

immutable ASCII_LOGO = q"DLIM
███╗   ██╗███████╗████████╗██╗    ██╗ ██████╗ ██████╗ ██╗  ██╗
████╗  ██║██╔════╝╚══██╔══╝██║    ██║██╔═══██╗██╔══██╗██║ ██╔╝
██╔██╗ ██║█████╗     ██║   ██║ █╗ ██║██║   ██║██████╔╝█████╔╝
██║╚██╗██║██╔══╝     ██║   ██║███╗██║██║   ██║██╔══██╗██╔═██╗
██║ ╚████║███████╗   ██║   ╚███╔███╔╝╚██████╔╝██║  ██║██║  ██╗
╚═╝  ╚═══╝╚══════╝   ╚═╝    ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝

               ███████╗████████╗ █████╗ ████████╗
               ██╔════╝╚══██╔══╝██╔══██╗╚══██╔══╝
               ███████╗   ██║   ███████║   ██║
               ╚════██║   ██║   ██╔══██║   ██║
               ███████║   ██║   ██║  ██║   ██║
               ╚══════╝   ╚═╝   ╚═╝  ╚═╝   ╚═╝
                                                by XILYOR.COM
DLIM";

struct NetStat {
    ulong recv;
    ulong sent;
}

NetStat getInterfaceStats(string iface) {
    version (linux)
    {
        try {
            auto content = readText("/proc/net/dev");
            auto lines = content.splitLines().drop(2);

            foreach (line; lines) {
                if (line.strip.startsWith(iface ~ ":")) {
                    auto tokens = line.split().filter!(a => !a.empty).array;
                    return NetStat(to!ulong(tokens[1]), to!ulong(tokens[9]));
                }
            }
        } catch (Exception e) {
            writeln("❌ Error reading stats: ", e.msg);
        }
    }
    else version (OSX)
    {
        try {
            auto output = execute(["netstat", "-ib"]);
            auto lines = output.output.splitLines();

            foreach (line; lines[1 .. $]) { // skip header
                auto tokens = line.strip.split().filter!(a => !a.empty).array;

                if (tokens.length >= 10 && tokens[0] == iface) {
                    ulong recv = to!ulong(tokens[6]);
                    ulong sent = to!ulong(tokens[9]);
                    return NetStat(recv, sent);
                }
            }
        } catch (Exception e) {
            writeln("❌ Failed to get stats via netstat: ", e.msg);
        }
    }
    else
    {
        writeln("❌ This OS is not yet supported.");
    }

    return NetStat(0, 0); // fallback
}

void listInterfaces()
{
    version (linux)
    {
        import std.file : readText;
        // import std.algorithm : drop;
        import std.string : splitLines;

        try {
            auto content = readText("/proc/net/dev");
            auto lines = content.splitLines().drop(2);
            writeln("📡 Available network interfaces:");
            foreach (line; lines) {
                auto iface = line.strip.split(":")[0];
                writeln("  🔌 ", iface);
            }
        } catch (Exception e) {
            writeln("❌ Failed to read interfaces: ", e.msg);
        }
    }
    else version (OSX)
    {
        try {
            auto output = execute(["/sbin/ifconfig", "-l"]);
            auto interfaces = output.output.strip.split(" ");
            writeln("📡 Available network interfaces:");
            foreach (iface; interfaces) {
                writeln("  🔌 ", iface);
            }
        } catch (Exception e) {
            writeln("❌ Failed to get interfaces via ifconfig: ", e.msg);
        }
    }
    else
    {
        writeln("❌ Sorry, this operating system is not supported yet.");
    }
}

string formatBytes(double value, string forcedUnit = "") {
    auto units = ["", "K", "M", "G", "T", "P"];
    double step = 1024.0;

    if (forcedUnit != "") {
        auto idx = units.countUntil(forcedUnit);
        if (idx < 0) return format("%.2f B/s ❌ Invalid unit", value);
        value /= step ^^ idx;
        return format("%.2f %sb/s", value, forcedUnit);
    }

    foreach (unit; units) {
        if (value < 1000.0)
            return format("%.0f %sb/s", value, unit);
        value /= step;
    }
    return format("%.2f Pb/s", value);
}

void showInterfaceData(string[] interfaces, int sleep, bool watch, string unit) {
    NetStat[string] prev;
    foreach (iface; interfaces) {
        prev[iface] = getInterfaceStats(iface);
    }

    if (watch) {
        writeln("\n"); // this creates empty lines because later it will goes up
        while (true) {
            Thread.sleep(dur!"seconds"(sleep));

            // Move cursor up: header + N interfaces
            writef("\033[%dA", interfaces.length + 1);

            writeln("🔄 Monitoring interfaces: ", interfaces);

            foreach (iface; interfaces) {
                auto current = getInterfaceStats(iface);
                auto down = (current.recv - prev[iface].recv) / sleep;
                auto up   = (current.sent - prev[iface].sent) / sleep;

                // Clear line, print new values
                write("\033[K"); // clear the current line
                writefln("📶 %s ⬇️ %s ⬆️ %s",
                         iface,
                         formatBytes(cast(double)down, unit),
                         formatBytes(cast(double)up, unit));

                prev[iface] = current;
            }
        }

    } else {
        writeln("📸 Taking a 1-second snapshot to estimate real-time speed...\n");
        Thread.sleep(dur!"seconds"(sleep));
        foreach (iface; interfaces) {
            auto current = getInterfaceStats(iface);
            auto down = (current.recv - prev[iface].recv) / sleep;
            auto up   = (current.sent - prev[iface].sent) / sleep;
            writeln("📶 ", iface, " ⬇️ ", formatBytes(cast(double)down, unit), " ⬆️ ", formatBytes(cast(double)up, unit));
        }
    }
}

void main(string[] args) {
    bool help = false, showVersion = false, list = false, watch = false;
    int sleep = DEFAULT_SLEEP;
    string ifaceArg, unit;

    getopt(args,
        "h|help", &help,
        "v|version", &showVersion,
        "l|list", &list,
        "w|watch", &watch,
        "s|sleep", &sleep,
        "u|unit", &unit,
    );

    if (help) {
        writeln(ASCII_LOGO);
        writeln("Usage: networkstat [options] [interfaces]");
        writeln("\nOptions:");
        writeln("  -h, --help           Show this help message");
        writeln("  -v, --version        Show version information");
        writeln("  -l, --list           List available network interfaces");
        writeln("  -w, --watch          Watch mode, updates every second");
        writeln("  -s, --sleep <sec>    Change watch sleep duration");
        writeln("  -u, --unit <B|K|M|G|T|P> Force output unit\n");
        writeln("Examples:");
        writeln("  networkstat --list");
        writeln("  networkstat enp0");
        writeln("  networkstat enp0:wlp4s0 --watch --sleep 2\n");
        return;
    }

    if (showVersion) {
        writeln("🌐 networkstat version ", VERSION);
        return;
    }

    if (list) {
        listInterfaces();
        return;
    }

    if (args.length < 2 || args[$-1].startsWith("-")) {
        writeln("❌ No interfaces provided. Use --help for usage.");
        return;
    }

    auto interfaces = args[$-1].split(":");
    showInterfaceData(interfaces, sleep, watch, unit);
}