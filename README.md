
# Mini-Zig

Mini-Zig is a Zig language utility designed to minify Zig source files by removing commented lines. It's a simple yet effective tool for developers looking to clean up their Zig code by stripping out unnecessary comments.

## Features

- **Remove Comments**: Efficiently removes single-line comments from Zig files.
- **Whitespace Handling**: Capable of handling files with leading whitespace before comments.
- **CLI Interface**: Easy-to-use command-line interface.
- **In-memory Processing**: Processes files entirely in memory for quick execution.

## Getting Started

### Prerequisites

- Install [Zig](https://ziglang.org/download/) 

### Installation

Clone the repository:

```bash
git clone https://github.com/ZakariaBouguira/mini-zig.git
cd mini-zig
```

### Usage

To minify a Zig file, run:

```bash
zig run mini.zig -- [path_to_zig_file]
```

Replace `[path_to_zig_file]` with the path to the Zig file you want to minify.

## Contributing

Contributions to Mini-Zig are welcome! If you have suggestions for improvements or encounter any issues, feel free to open an issue or submit a pull request.

## License

This project is licensed under the MIT License - see the LICENSE file for more details.

## Acknowledgements

- Thanks to the Zig community for their invaluable resources and support.