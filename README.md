# 📡 networkstat

A stylish, emoji-powered command-line tool to monitor real-time network interface stats — built with Python by [Xilyor](https://xilyor.com).  
Supports multiple interfaces, watch mode, unit scaling, colored output, config persistence, and man page support.

![License](https://img.shields.io/github/license/yourusername/networkstat)
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
- 🖥️ Supports multiple interfaces via `|` pipe separator

---

## 📦 Installation

### 🛠️ Prerequisites

- Python 3.6+
- `psutil` Python module:
  ```bash
  pip install psutil

