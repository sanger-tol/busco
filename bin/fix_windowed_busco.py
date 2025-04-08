#!/usr/bin/env python3

import argparse
import os
import sys
import shutil
import re

def parse_args():
    parser = argparse.ArgumentParser(
        description="Fix BUSCO output directory from chunked chromosome runs (e.g., due to Prodigal limitations)."
    )
    parser.add_argument(
        "busco_dir",
        help="Path to the BUSCO output directory (e.g., run_archaea_odb10)."
    )
    return parser.parse_args()

def fix_full_table(input_path, output_path):
    input_file = os.path.join(input_path, "full_table.tsv")
    output_file = os.path.join(output_path, "full_table.tsv")

    if not os.path.exists(input_file):
        print(f"Warning: full_table.tsv not found in {input_path}", file=sys.stderr)
        return

    with open(input_file, "r") as fin, open(output_file, "w") as fout:
        for line in fin:
            if line.startswith("#") or line.strip() == "":
                fout.write(line)
                continue

            fields = line.rstrip("\n").split("\t")

            if len(fields) < 2 or fields[1] == "Missing":
                fout.write(line)
                continue

            seq = fields[2]
            try:
                local_start = int(fields[3])
                local_end = int(fields[4])
            except (IndexError, ValueError):
                fout.write(line)
                continue

            if "_sliding:" not in seq:
                fout.write(line)
                continue

            try:
                contig_part, range_part = seq.split("_sliding:")
                window_start_str, _ = range_part.split("-")
                window_start = int(window_start_str)
            except ValueError:
                fout.write(line)
                continue

            corrected_start = window_start + local_start - 1
            corrected_end = window_start + local_end - 1

            fields[2] = contig_part
            fields[3] = str(corrected_start)
            fields[4] = str(corrected_end)

            fout.write("\t".join(fields) + "\n")

    print(f"Corrected full_table.tsv written to: {output_file}")

def fix_busco_sequences(input_path, output_path):
    seq_dir = "busco_sequences"
    seq_subdirs = [
        "fragmented_busco_sequences",
        "multi_copy_busco_sequences",
        "single_copy_busco_sequences"
    ]

    for subdir in seq_subdirs:
        in_dir = os.path.join(input_path, seq_dir, subdir)
        out_dir = os.path.join(output_path, seq_dir, subdir)
        os.makedirs(out_dir, exist_ok=True)

        if not os.path.isdir(in_dir):
            print(f"Warning: expected directory not found: {in_dir}", file=sys.stderr)
            continue

        for filename in os.listdir(in_dir):
            if not (filename.endswith(".fna") or filename.endswith(".faa")):
                continue

            in_file = os.path.join(in_dir, filename)
            out_file = os.path.join(out_dir, filename)

            with open(in_file, "r") as fin, open(out_file, "w") as fout:
                for line in fin:
                    if line.startswith(">"):
                        match = re.match(
                            r"^>([^_]+)_sliding:(\d+)-\d+:(\d+)-(\d+)(\|[+-])", line.strip()
                        )
                        if not match:
                            print(f"Warning: malformed FASTA header in {filename}: {line.strip()}", file=sys.stderr)
                            fout.write(line)
                            continue

                        contig, window_start_str, local_start_str, local_end_str, strand = match.groups()
                        window_start = int(window_start_str)
                        local_start = int(local_start_str)
                        local_end = int(local_end_str)

                        corrected_start = window_start + local_start - 1
                        corrected_end = window_start + local_end - 1

                        new_header = f">{contig}:{corrected_start}-{corrected_end}{strand}"
                        fout.write(new_header + "\n")
                    else:
                        fout.write(line)

    print(f"Corrected busco_sequences written to: {os.path.join(output_path, seq_dir)}")

def fix_prodigal_output(input_path, output_path):
    input_dir = os.path.join(input_path, "prodigal_output", "predicted_genes")
    output_dir = os.path.join(output_path, "prodigal_output", "predicted_genes")
    os.makedirs(output_dir, exist_ok=True)

    for filename in ["predicted.fna", "predicted.faa"]:
        in_file = os.path.join(input_dir, filename)
        out_file = os.path.join(output_dir, filename)

        if not os.path.exists(in_file):
            print(f"Warning: {filename} not found in {input_dir}", file=sys.stderr)
            continue

        with open(in_file, "r") as fin, open(out_file, "w") as fout:
            for line in fin:
                if not line.startswith(">"):
                    fout.write(line)
                    continue

                try:
                    header, meta = line[1:].strip().split(" # ", 1)
                    contig_chunk, gene_id = header.rsplit("_", 1)
                    contig, sliding = contig_chunk.split("_sliding:")
                    window_start_str, _ = sliding.split("-")
                    window_start = int(window_start_str)

                    meta_fields = meta.split(" # ")
                    local_start = int(meta_fields[0])
                    local_end = int(meta_fields[1])
                    strand = meta_fields[2]
                    rest = " # ".join(meta_fields[3:])

                    corrected_start = window_start + local_start - 1
                    corrected_end = window_start + local_end - 1

                    new_header = f">{contig}_{gene_id} # {corrected_start} # {corrected_end} # {strand} # {rest}"
                    fout.write(new_header + "\n")
                except Exception as e:
                    print(f"Warning: could not parse header in {filename}: {line.strip()}", file=sys.stderr)
                    fout.write(line)

    print(f"Corrected prodigal output written to: {output_dir}")

def fix_hmmer_output(input_path, output_path):
    in_dir = os.path.join(input_path, "hmmer_output")
    out_dir = os.path.join(output_path, "hmmer_output")
    os.makedirs(out_dir, exist_ok=True)

    for filename in os.listdir(in_dir):
        if not filename.endswith(".out"):
            continue

        in_file = os.path.join(in_dir, filename)
        out_file = os.path.join(out_dir, filename)

        with open(in_file, "r") as fin, open(out_file, "w") as fout:
            for line in fin:
                if line.startswith("#") or line.strip() == "":
                    fout.write(line)
                    continue

                parts = line.rstrip("\n").split()
                if len(parts) < 1:
                    fout.write(line)
                    continue

                original_target = parts[0]
                match = re.match(
                    r"^([^\s_]+)_sliding:(\d+)-\d+:(\d+)-(\d+)(\|\S*)$", original_target
                )
                if not match:
                    fout.write(line)
                    continue

                contig, win_start_str, local_start_str, local_end_str, suffix = match.groups()
                try:
                    win_start = int(win_start_str)
                    local_start = int(local_start_str)
                    local_end = int(local_end_str)
                except ValueError:
                    fout.write(line)
                    continue

                corrected_start = win_start + local_start - 1
                corrected_end = win_start + local_end - 1
                corrected_target = f"{contig}:{corrected_start}-{corrected_end}{suffix}"
                parts[0] = corrected_target

                if "#" in line:
                    data_part, comment_part = line.split("#", 1)
                    comment = f"# {comment_part.strip()}"
                    comment = re.sub(
                        r"([^\s_]+)_sliding:(\d+)-\d+_(\d+) # (\d+) # (\d+) #",
                        lambda m: f"{m.group(1)}_{m.group(3)} # {int(m.group(2)) + int(m.group(4)) - 1} # {int(m.group(2)) + int(m.group(5)) - 1} #",
                        comment
                    )
                    fout.write(" ".join(parts) + " " + comment + "\n")
                else:
                    fout.write(" ".join(parts) + "\n")

    print(f"Corrected HMMER output written to: {out_dir}")

def main():
    args = parse_args()

    if not os.path.isdir(args.busco_dir):
        print(f"Error: {args.busco_dir} is not a valid directory", file=sys.stderr)
        sys.exit(1)

    base_name = os.path.basename(os.path.normpath(args.busco_dir))
    new_dir = os.path.join(os.path.dirname(args.busco_dir), f"fixed_{base_name}")
    os.makedirs(new_dir, exist_ok=True)
    print(f"Created or verified new directory: {new_dir}")

    files_to_copy = [
        "short_summary.txt",
        "short_summary.json",
        "missing_busco_list.tsv"
    ]
    for filename in files_to_copy:
        src = os.path.join(args.busco_dir, filename)
        dst = os.path.join(new_dir, filename)
        if os.path.exists(src):
            shutil.copy(src, dst)
            print(f"Copied {filename} to {new_dir}")
        else:
            print(f"Warning: {filename} not found in {args.busco_dir}", file=sys.stderr)

    fix_full_table(args.busco_dir, new_dir)
    fix_busco_sequences(args.busco_dir, new_dir)
    fix_prodigal_output(args.busco_dir, new_dir)
    fix_hmmer_output(args.busco_dir, new_dir)

if __name__ == "__main__":
    main()
