#!/usr/bin/env python3
import sys
import time
import os
import psutil
import argparse
import shutil

# Constants
VERSION = "1.3.19"
DEFAULT_SLEEP = 1
# link to make text art: https://patorjk.com/software/taag/
# font name: ANSI Shadow
ASCII_LOGO = r"""
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
"""

def list_interfaces():
    print("📡 Available network interfaces:")
    for interface in psutil.net_if_addrs():
        print(f"  🔌 {interface}")

def get_interface_stats(interface):
    try:
        stats = psutil.net_io_counters(pernic=True)[interface]
        return stats.bytes_recv, stats.bytes_sent
    except KeyError:
        return None

def show_interface_data(interfaces, sleep, watch=False, unit=None):
    def read_counters():
        return {
            iface: psutil.net_io_counters(pernic=True).get(iface)
            for iface in interfaces
        }

    if watch:
        try:
            prev = read_counters()
            while True:
                time.sleep(sleep)
                os.system("clear")
                print(f"🔄 Monitoring interfaces every {sleep} second(s)...\n")
                current = read_counters()
                for iface in interfaces:
                    if prev[iface] and current[iface]:
                        down_diff = current[iface].bytes_recv - prev[iface].bytes_recv
                        up_diff = current[iface].bytes_sent - prev[iface].bytes_sent
                        print(f"📶 {iface} ⬇️ {format_bytes(down_diff / sleep, unit)} ⬆️ {format_bytes(up_diff / sleep, unit)}")
                    else:
                        print(f"⚠️ Interface '{iface}' not found.")
                prev = current
        except KeyboardInterrupt:
            print("\n🛑 Watch stopped.")
    else:
        # Snapshot mode: sleep briefly between reads
        print(f"📸 Taking a 1-second snapshot to estimate real-time speed...\n")
        prev = read_counters()
        time.sleep(sleep)
        current = read_counters()

        for iface in interfaces:
            if prev[iface] and current[iface]:
                down_diff = current[iface].bytes_recv - prev[iface].bytes_recv
                up_diff = current[iface].bytes_sent - prev[iface].bytes_sent
                print(f"📶 {iface} ⬇️ {format_bytes(down_diff / sleep, unit)} ⬆️ {format_bytes(up_diff / sleep, unit)}")
            else:
                print(f"⚠️ Interface '{iface}' not found.")

def format_bytes(value, forced_unit=None):
    units = [' ', 'K', 'M', 'G', 'T', 'P']
    step = 1024.0

    if forced_unit:
        forced_unit = forced_unit.upper()
        if forced_unit not in units:
            return f"{value:.2f} B/s ❌ Invalid unit"
        idx = units.index(forced_unit)
        scaled = value / (step ** idx)
        return f"{scaled:.2f} {forced_unit}b/s"

    # Auto-scale logic (max 3 digits before decimal)
    for unit in units:
        if value < 1000:
            return f"{value:.0f} {unit}b/s"
        value /= step
    return f"{value:.2f} Pb/s"


def main():
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("interfaces", nargs="?", default=None)
    parser.add_argument("-l", "--list", action="store_true")
    parser.add_argument("-v", "--version", action="store_true")
    parser.add_argument("-h", "--help", action="store_true")
    parser.add_argument("-w", "--watch", action="store_true")
    parser.add_argument("-s", "--sleep", type=int, default=DEFAULT_SLEEP)
    parser.add_argument("-u", "--unit", type=str, help="Force output unit (B|K|M|G|T|P)")
    
    args = parser.parse_args()

    if args.help:
        print(ASCII_LOGO)
        print("""
Usage: networkstat [options] [interfaces]

Options:
  -h, --help           Show this help message
  -v, --version        Show version information
  -l, --list           List available network interfaces
  -w, --watch          Watch mode, updates every second
  -s, --sleep <sec>    Change watch sleep duration

Examples:
  networkstat --list
  networkstat enp0
  networkstat enp0|wlp4s0 --watch --sleep 2
        """)
        return

    if args.version:
        print(f"🌐 networkstat version {VERSION}")
        return

    if args.list:
        list_interfaces()
        return

    if not args.interfaces:
        print("❌ No interfaces provided. Use --help for usage.")
        return
    

    # 👇 Add this before show_interface_data
    sleep = args.sleep if args.sleep is not None else config.get('default_sleep', DEFAULT_SLEEP_FALLBACK)

    interfaces = args.interfaces.split("|")
    show_interface_data(interfaces, sleep, watch=args.watch, unit=args.unit)

if __name__ == "__main__":
    main()

