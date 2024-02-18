
# Mini-Zig

Mini-Zig is a Zig language utility designed to minify Zig source files by removing commented lines. It's a simple yet effective tool for developers looking to clean up their Zig code by stripping out unnecessary comments.
It also provides options for keeping documentation comments and trimming spaces, offering a customizable approach to streamline your Zig code.



## Features

- **Remove Full-Line and Inline Comments**: Mini-Zig removes both full-line comments (starting with `//`) and inline comments (comments that appear on the same line after code).
- **Keep Documentation Comments**: Option to retain documentation comments (`///`) in the source files.
- **Trim Spaces**: Ability to trim leading and trailing spaces from each line in the source file for a cleaner look.
- **Flexible Output Options**: Choose to overwrite the input file or specify a different output file.
- **Command-Line Interface**: Enhanced command-line interface with options for different minification needs.
- **In-memory Processing**: Efficient in-memory processing for quick execution.



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

Run Mini-Zig with various options:

```bash
zig run mini.zig -- [options] <file_path>
```

To keep documentation comments, use the `-keep-doc` flag:

```bash
zig run mini.zig -- [path_to_zig_file] -keep-doc
```

**Options:**
- `-h`, `--help`: Print the help message.
- `-o`, `--output <file>`: Specify the output file (default is to overwrite the input file).
- `-d`, `--doc`: Keep documentation comments.
- `-s`, `--spaces`: Trim spaces.

**Example:**

```bash
zig run mini-zig.zig -- -o output.zig -d -s input.zig
```

## Contributing

Contributions to Mini-Zig are welcome! If you have suggestions for improvements or encounter any issues, feel free to open an issue or submit a pull request.

## License

This project is licensed under the MIT License - see the LICENSE file for more details.

## Acknowledgements

- Thanks to the Zig community for their invaluable resources and support.