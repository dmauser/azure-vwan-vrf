#! /bin/bash
echo "Testing connectivity to various IP addresses using curl"
echo "--------------------------------------------------"

# Get the host's IP addresses
host_ips=$(hostname -I)

# Function to check if an IP is in the host's IPs
function is_host_ip() {
    local ip=$1
    [[ $host_ips =~ (^|[[:space:]])$ip($|[[:space:]]) ]]
}

# List of target IPs
target_ips=(
    "10.100.0.4"
    "10.110.0.4"
    "10.120.0.4"
    "172.16.100.4"
    "172.16.3.4"
    "172.16.4.4"
    "172.16.5.4"
    "172.16.6.4"
    "172.16.2.4"
    "172.16.1.4"
)

# Loop through each target IP
for ip in "${target_ips[@]}"; do
    if is_host_ip "$ip"; then
        echo "Skipping $ip (matches host IP)"
        continue
    fi
    echo "$ip"
    curl --max-time 5 "$ip"
done