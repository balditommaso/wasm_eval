import csv
import sys

def parse_sim_cyclictest(input_file, output_csv):
    """
    Parses the pure X Y output from the custom WebAssembly cyclictest simulator.
    """
    extracted_data = []

    with open(input_file, 'r', encoding='utf-8') as f:
        for line in f:
            # Skip metadata and summary lines starting with '#'
            if line.startswith('#'):
                continue
            
            parts = line.strip().split()
            # We are looking strictly for lines with exactly two numbers: Cycle and Latency
            if len(parts) == 2:
                try:
                    cycle = int(parts[0])
                    latency = int(parts[1])
                    extracted_data.append([cycle, latency])
                except ValueError:
                    # Ignore any rogue lines that aren't integers
                    continue

    if not extracted_data:
        print("Error: Could not find valid Cycle/Latency data in the file.")
        return

    # Write to CSV
    headers = ["Cycle", "Latency_us"]
    with open(output_csv, 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(headers)
        writer.writerows(extracted_data)

    print(f"Successfully extracted {len(extracted_data)} data points to {output_csv}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python parse_trace.py <input_trace.txt> <output.csv>")
        sys.exit(1)
    
    parse_sim_cyclictest(sys.argv[1], sys.argv[2])