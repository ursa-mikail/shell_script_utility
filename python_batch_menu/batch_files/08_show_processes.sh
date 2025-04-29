#!/bin/bash
# 08_show_processes.sh - Show top CPU consuming processes

echo "Top CPU consuming processes:"
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head

# ✅ Useful for spotting heavy processes quickly.
