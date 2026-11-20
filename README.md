# Ubuntu VM Health Check

A Bash script that reports whether an Ubuntu virtual machine is healthy by measuring:

- CPU usage
- Memory usage
- Disk usage for the root filesystem

The VM is **healthy** only when all three usage values are below 60%. If any value is 60% or higher, the VM is **unhealthy**.

## Requirements

- Ubuntu Linux
- Bash
- Standard commands: `awk`, `df`, and `free`

No packages beyond Ubuntu's standard command-line tools are required.

## Installation

```bash
git clone https://github.com/Bikkythecoder/ubuntu-vm-health-check.git
cd ubuntu-vm-health-check
chmod +x vm_health.sh
```

## Usage

Print the health status and usage metrics:

```bash
./vm_health.sh
```

Print the metrics, health status, and an explanation:

```bash
./vm_health.sh explain
```

## Exit Codes

- `0`: Healthy; all monitored usage values are below 60%
- `1`: Unhealthy; one or more usage values are at or above 60%
- `2`: Script usage or measurement error

## Example Output

Healthy:

```text
CPU usage:    12.5%
Memory usage: 42.3%
Disk usage:   38%
VM state: HEALTHY
Reason: CPU, memory, and disk usage are all below 60%.
```

Unhealthy:

```text
CPU usage:    71.2%
Memory usage: 54.1%
Disk usage:   45%
VM state: UNHEALTHY
Reason: CPU usage is 71.2%, which is at or above 60%.
```

## How It Works

- **CPU:** Samples `/proc/stat` one second apart and calculates the increase in non-idle time as a percentage.
- **Memory:** Uses `free -b` and compares available memory with total memory.
- **Disk:** Uses `df -P /` to measure usage of the filesystem containing `/`.

## License

MIT
