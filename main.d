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

enum VERSION = "1.3.28";
enum DEFAULT_SLEEP = 1;

immutable ASCII_LOGO = q"DLIM
███╗   ██╗███████╗████████╗██╗    ██╗ ██████╗ ██████╗ ██╗  ██╗
████╗  ██║██╔════╝╚══██╔══╝██║    ██║██╔═══██╗██╔══██╗██║ ██╔╝
██╔██╗ ██║█████╗     ██║   ██║ █╗ ██║██║   ██║██████╔╝█████╔╝ 
██║╚██╗██║██╔══╝     ██║   ██║███╗██║██║   ██║██╔══██╗██╔═██╗ 
██║ ╚████║███████╗   ██║   ╚███╔███╔╝╚██████╔╝██║  ██║██║  ██╗
╚═╝  ╚═══╝╚══════╝   ╚═╝    ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝
        by XILYOR.COM
DLIM";

struct NetStat {
    ulong recv;
    ulong sent;
}

NetStat getInterfaceStats(string iface) {
    auto lines = File("/proc/net/dev").byLineCopy.drop(2);
    foreach (line; lines) {
        if (line.strip.startsWith(iface ~ ":")) {
            auto tokens = line.split().filter!(a => !a.empty).array;
            return NetStat(to!ulong(tokens[1]), to!ulong(tokens[9]));
        }
    }
    return NetStat(0, 0); // fallback
}

void listInterfaces() {
    writeln("📡 Available network interfaces:");
    foreach (line; File("/proc/net/dev").byLineCopy.drop(2)) {
        auto name = line.strip.split(":")[0].strip;
        writeln("  🔌 ", name);
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

            writeln("🔄 Monitoring interfaces every ", sleep, " second(s)...");

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
        writeln("  networkstat enp0|wlp4s0 --watch --sleep 2\n");
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

    auto interfaces = args[$-1].split("|");
    showInterfaceData(interfaces, sleep, watch, unit);
}