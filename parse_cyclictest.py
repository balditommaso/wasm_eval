import re
import csv
import sys



def parse_live_cyclictest(input_file, output_csv):
    """
    Parses live cyclictest console output, ignoring ANSI escape codes,
    and extracts cycle-by-cycle latency metrics.
    """
    # Regex to match the core data line, e.g.:
    # T: 0 (  231) P:99 I:1000 C:   1390 Min:      3 Act:     3 Avg:    18 Max:     181
    pattern = re.compile(
        r'C:\s+(?P<Cycle>\d+)\s+'
        r'Min:\s+(?P<Min>\d+)\s+'
        r'Act:\s+(?P<Act>\d+)\s+'
        r'Avg:\s+(?P<Avg>\d+)\s+'
        r'Max:\s+(?P<Max>\d+)'
    )

    extracted_data = []

    with open(input_file, 'r', encoding='utf-8', errors='ignore') as f:
        for line in f:
            # Clean ANSI escape codes (like \033[3A) from the line
            clean_line = re.sub(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])', '', line)
            
            match = pattern.search(clean_line)
            if match:
                extracted_data.append([
                    int(match.group('Cycle')),
                    int(match.group('Min')),
                    int(match.group('Act')),
                    int(match.group('Avg')),
                    int(match.group('Max'))
                ])

    if not extracted_data:
        print("Error: Could not find matching time-series data in the file.")
        return

    # Write to CSV
    headers = ["Cycle", "Min_us", "Act_us", "Avg_us", "Max_us"]
    with open(output_csv, 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(headers)
        writer.writerows(extracted_data)

    print(f"Successfully extracted {len(extracted_data)} data points to {output_csv}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python parse_trace.py <input_trace.txt> <output.csv>")
        sys.exit(1)
    
    parse_live_cyclictest(sys.argv[1], sys.argv[2])