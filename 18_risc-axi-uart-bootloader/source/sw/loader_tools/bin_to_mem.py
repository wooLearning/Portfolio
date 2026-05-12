from pathlib import Path
import argparse


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--words", type=int, default=0)
    args = parser.parse_args()

    data = args.input.read_bytes()
    if len(data) % 4:
        data += bytes(4 - (len(data) % 4))

    words = []
    for index in range(0, len(data), 4):
        chunk = data[index:index + 4]
        word = int.from_bytes(chunk, byteorder="little")
        words.append(f"{word:08x}")

    if args.words and len(words) < args.words:
        words.extend(["00000013"] * (args.words - len(words)))

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text("\n".join(words) + "\n", encoding="ascii")


if __name__ == "__main__":
    main()
