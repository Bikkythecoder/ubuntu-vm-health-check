#!/usr/bin/env bash

set -u

if [[ $# -gt 1 || ( $# -eq 1 && "$1" != "explain" ) ]]; then
  echo "Usage: $0 [explain]" >&2
  exit 2
fi

explain=false
[[ $# -eq 1 ]] && explain=true

# Verify required Ubuntu commands.
for command_name in awk df free; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Required command not found: $command_name" >&2
    exit 2
  fi
done

cpu_snapshot() {
  awk '/^cpu / {
    idle = $5 + $6
    total = 0
    for (i = 2; i <= NF; i++) total += $i
    printf "%.0f %.0f\n", total, idle
  }' /proc/stat
}

read -r total1 idle1 < <(cpu_snapshot)
sleep 1
read -r total2 idle2 < <(cpu_snapshot)

cpu_usage=$(awk -v t1="$total1" -v i1="$idle1" \
                 -v t2="$total2" -v i2="$idle2" 'BEGIN {
  total_delta = t2 - t1
  idle_delta = i2 - i1
  if (total_delta <= 0) print "0"
  else printf "%.1f", 100 * (total_delta - idle_delta) / total_delta
}')

read -r memory_total memory_available < <(
  free -b | awk '$1 == "Mem:" { print $2, $7 }'
)

if [[ -z "${memory_total:-}" || "$memory_total" -le 0 ]]; then
  echo "Could not determine memory usage." >&2
  exit 2
fi

memory_usage=$(awk -v total="$memory_total" -v available="$memory_available" \
  'BEGIN { printf "%.1f", 100 * (total - available) / total }')

disk_usage=$(df -P / | awk 'NR == 2 { gsub(/%/, "", $5); print $5 }')

if [[ -z "${disk_usage:-}" ]]; then
  echo "Could not determine disk usage." >&2
  exit 2
fi

printf 'CPU usage:    %s%%\n' "$cpu_usage"
printf 'Memory usage: %s%%\n' "$memory_usage"
printf 'Disk usage:   %s%%\n' "$disk_usage"

unhealthy=false
reasons=()

if awk -v value="$cpu_usage" 'BEGIN { exit !(value > 60) }'; then
  unhealthy=true
  reasons+=("CPU usage is ${cpu_usage}%, which is above 60%." )
fi

if awk -v value="$memory_usage" 'BEGIN { exit !(value > 60) }'; then
  unhealthy=true
  reasons+=("Memory usage is ${memory_usage}%, which is above 60%." )
fi

if awk -v value="$disk_usage" 'BEGIN { exit !(value > 60) }'; then
  unhealthy=true
  reasons+=("Disk usage is ${disk_usage}%, which is above 60%." )
fi

if [[ "$unhealthy" == true ]]; then
  echo "VM state: UNHEALTHY"
  if [[ "$explain" == true ]]; then
    printf 'Reason: %s\n' "${reasons[@]}"
  fi
  exit 1
else
  echo "VM state: HEALTHY"
  if [[ "$explain" == true ]]; then
    echo "Reason: CPU, memory, and disk usage are 60% or below."
  fi
  exit 0
fi
