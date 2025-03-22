#!/usr/bin/env python3
import sys
import time
import os
import psutil
import argparse
import shutil

# Constants
VERSION = "1.0.0"
DEFAULT_SLEEP = 1
ASCII_LOGO = r"""
██╗  ██╗██╗██╗     ██╗   ██╗ ██████╗ ██████╗ ██████╗ 
██║ ██╔╝██║██║     ██║   ██║██╔════╝ ██╔══██╗██╔══██╗
█████╔╝ ██║██║     ██║   ██║██║  ███╗██████╔╝██████╔╝
██╔═██╗ ██║██║     ██║   ██║██║   ██║██╔═══╝ ██╔═══╝ 
██║  ██╗██║███████╗╚██████╔╝╚██████╔╝██║     ██║     
╚═╝  ╚═╝╚═╝╚══════╝ ╚═════╝  ╚═════╝ ╚═╝     ╚═╝     
                     by XILYOR
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

def show_interface_data(interfaces, sleep, watch=False):
    if watch:
        try:
            while True:
                os.system('clear')
                print(f"🔄 Monitoring interfaces every {sleep} second(s)...\n")
                for iface in interfaces:
                    stats = get_interface_stats(iface)
                    if stats:
                        down, up = stats
                        print(f"📶 {iface} ⬇️ {down / 1024:.2f} KB ⬆️ {up / 1024:.2f} KB")
                    else:
                        print(f"⚠️ Interface '{iface}' not found.")
                time.sleep(sleep)
        except KeyboardInterrupt:
            print("\n🛑 Watch stopped.")
    else:
        for iface in interfaces:
            stats = get_interface_stats(iface)
            if stats:
                down, up = stats
                print(f"📶 {iface} ⬇️ {down / 1024:.2f} KB ⬆️ {up / 1024:.2f} KB")
            else:
                print(f"⚠️ Interface '{iface}' not found.")

def main():
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("interfaces", nargs="?", default=None)
    parser.add_argument("-l", "--list", action="store_true")
    parser.add_argument("-v", "--version", action="store_true")
    parser.add_argument("-h", "--help", action="store_true")
    parser.add_argument("-w", "--watch", action="store_true")
    parser.add_argument("-s", "--sleep", type=int, default=DEFAULT_SLEEP)
    
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

    interfaces = args.interfaces.split("|")
    show_interface_data(interfaces, args.sleep, watch=args.watch)

if __name__ == "__main__":
    main()

