# 📱 networkstat

A stylish, emoji-powered command-line tool to monitor real-time network interface stats — built with Python by [Xilyor](https://www.xilyor.com).  
Supports multiple interfaces, watch mode, unit scaling, colored output, config persistence, and man page support.

![License](https://img.shields.io/github/license/mohamedelleuch/networkstat)
![Python](https://img.shields.io/badge/Python-3.6%2B-blue)
![Status](https://img.shields.io/badge/status-active-brightgreen)

---

## ✨ Features

- 📶 Show upload & download speeds per interface
- 🔄 Watch mode with configurable update intervals
- 📚 Man page installed globally with `man networkstat`
- ⚙️ Persistent config file (default sleep duration, etc.)
- 🧠 Smart unit formatting (auto or forced: B|K|M|G|T|P)
- 🎨 Clean output with emojis and optional colors
- 💻 Supports multiple interfaces via `|` pipe separator

---

## 📦 Installation

### 🛠️ Prerequisites

- Python 3.6+
- `psutil` Python module:
  ```bash
  pip install psutil
  ```

### 🚀 Install globally

```bash
git clone https://github.com/yourusername/networkstat.git
cd networkstat
chmod +x setup.sh
./setup.sh
```

> This will:
> - Install `networkstat.py` as a global CLI tool
> - Install man page
> - Create default config file at `~/.config/networkstat/config.json`

---

## ⚡ Usage

```bash
networkstat [options] [interfaces]
```

### 🧪 Examples

```bash
# List available interfaces
networkstat --list

# Show stats for enp0s3
networkstat enp0s3

# Show multiple interfaces
networkstat enp0s3|wlp2s0

# Watch mode with 2-second refresh
networkstat enp0s3 --watch --sleep 2

# Set default sleep interval
networkstat --default-sleep 3

# Force unit to MB
networkstat enp0s3 --unit M
```

---

## 🦾 Options

| Flag                  | Description                                                |
|-----------------------|------------------------------------------------------------|
| `-h`, `--help`        | Show help with ASCII logo and usage guide                  |
| `-v`, `--version`     | Display version info                                       |
| `-l`, `--list`        | List available network interfaces                          |
| `-w`, `--watch`       | Continuously monitor stats                                 |
| `-s`, `--sleep`       | Set custom refresh interval (used only for this session)   |
| `-ds`, `--default-sleep` | Persistently change default sleep interval             |
| `-u`, `--unit`        | Force output unit: `B`, `K`, `M`, `G`, `T`, `P`             |

---

## 🧠 Output Logic

- 📏 **Auto-scaling output** with maximum 3 significant digits
  - `421` → `421 b/s`
  - `8379` → `8.37 Kb/s`
  - `8122876` → `8.12 Mb/s`
- Force any unit using `--unit M` etc.

---

## 📁 Config

- Location: `~/.config/networkstat/config.json`

```json
{
  "default_sleep": 1
}
```

---

## 📖 Man Page

After install, you can view usage via:

```bash
man networkstat
```

---

## 🧑‍💻 Author

**Mohamed Elleuch**  
Founder of [Xilyor](https://xilyor.com)  
📧 Email: [mohamed.elleuch@xilyor.com](mailto:mohamed.elleuch@xilyor.com)  
🐙 GitHub: [@mohamedelleuch](https://github.com/mohamedelleuch)

---

## ⚖️ License

This project is licensed under the [Apache License 2.0](LICENSE)

---

## 💡 Contributions

Pull requests, feature suggestions, and issues are welcome. Let’s make `networkstat` even cooler together!


