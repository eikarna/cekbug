#!/bin/bash

# Check if nmap package is installed
if ! command -v nmap &> /dev/null; then
    echo "Error: nmap package is not installed."
    echo "Please install nmap and try again."
    exit 1
fi

# Check if both port and target arguments are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <target> <port>"
    exit 1
fi

# Extract target and port from command-line arguments
target="$1"
port="$2"

# Validate port number
if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
    echo "Invalid port number. Please enter a number between 1 and 65535."
    exit 1
fi

# Run nmap and store the output
output=$(nmap -p "$port" -script dns-brute.nse "$target")

# Check if nmap command was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to execute nmap command."
    exit 1
fi

# Extract domain names and IP addresses from the output using awk
result=$(echo "$output" | awk '/DNS Brute-force hostnames:/ {flag=1; next} /^\|/ && !/dns-brute:/ {print $2 "|" $NF} /^|_/ {flag=0} flag')

# Print the extracted results with auto-ellipsis
if [ -n "$result" ]; then
    # Determine the maximum length of domain names and IP addresses
    max_domain_length=0
    max_ip_length=0
    while IFS='|' read -r domain ip; do
        domain_length=${#domain}
        ip_length=${#ip}
        if [ "$domain_length" -gt "$max_domain_length" ]; then
            max_domain_length="$domain_length"
        fi
        if [ "$ip_length" -gt "$max_ip_length" ]; then
            max_ip_length="$ip_length"
        fi
    done <<< "$result"

    # Add extra spacing between domain and IP address columns
    max_domain_length=$((max_domain_length + 2))

    # Print the table header
    printf "%-*s %-*s\n" "$max_domain_length" "Domain Name" "$max_ip_length" "IP Address"
    printf "%-*s %-*s\n" "$max_domain_length" "----------------" "$max_ip_length" "----------"

    # Print the extracted results with auto-ellipsis
    while IFS='|' read -r domain ip; do
        # Truncate long IP addresses with auto-ellipsis
        truncated_ip=$ip
        if [ ${#ip} -gt 16 ]; then
            truncated_ip="${ip:0:13}     <-- Truncated"
        fi
        printf "%-*s %-*s\n" "$max_domain_length" "$domain" "$max_ip_length" "$truncated_ip"
    done <<< "$result"
else
    echo "No domain names and IP addresses found."
fi
