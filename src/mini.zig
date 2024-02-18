const std = @import("std");

fn printHelp() void {
    std.debug.print(
        \\Usage: mini-zig [options] <file>
        \\Options:
        \\  -h, --help            Print this help message
        \\  -o, --output <file>   Specify the output file
        \\  -d, --doc             Keep doc comments
        \\  -s, --spaces          Trim spaces
        \\
        \\Example:
        \\  zig build run -- -o output.zig -d -s input.zig
        \\
        \\By default, mini-zig will remove all doc comments, keep all spaces and write the output to the same input file.
        \\
    , .{});

    return;
}

const Options = struct {
    help: bool = false,
    keep_doc_comments: bool = false,
    trim_spaces: bool = false,
    output: ?[]const u8 = null,
};

const Cli = struct {
    allocator: *std.mem.Allocator,
    args: []const [:0]u8,
    file_path: ?[]const u8 = null,
    options: Options,

    const Self = @This();
    fn init(allocator: *std.mem.Allocator) !Self {
        var self = Self{
            .allocator = allocator,
            .args = undefined,
            .options = undefined,
            .file_path = null,
        };

        self.args = try std.process.argsAlloc(allocator.*);
        if (self.args.len < 2) {
            self.file_path = try getFilePath(allocator);
        } else {
            self.options = try self.parseArgs(self.args);
        }
        return self;
    }
    fn deinit(self: *Self) void {
        if (self.args.len < 2) {
            self.allocator.*.free(self.file_path.?);
        }
        std.process.argsFree(self.allocator.*, self.args);
    }

    fn getFilePath(allocator: *std.mem.Allocator) ![]const u8 {
        const stdout = std.io.getStdOut().writer();
        const stdin = std.io.getStdIn().reader();
        try stdout.writeAll("\nEnter the file path to minify.\n");
        try stdout.writeAll("> ");
        const file_path = try stdin.readUntilDelimiterOrEofAlloc(allocator.*, '\n', 1024) orelse {
            std.log.err("Failed to read input.\n", .{});
            return error.FailedToReadInput;
        };
        return std.mem.trimRight(u8, file_path, "\n");
    }

    fn parseArgs(self: *Self, args: []const [:0]u8) !Options {
        var options = Options{};

        var arg_counter: usize = 1;
        while (arg_counter < args.len) : (arg_counter += 1) {
            const arg = args[arg_counter];
            if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
                options.help = true;
                return options;
            } else if (std.mem.eql(u8, arg, "-o") or std.mem.eql(u8, arg, "--output")) {
                if (arg_counter == args.len) {
                    std.log.err("Output file path is missing.\n", .{});
                    std.log.err("Usage: mini-zig -- -o output.zig [options] input.zig\n", .{});
                    return error.OutputFileMissing;
                } else {
                    const output = args[arg_counter + 1];
                    if (std.mem.startsWith(u8, output, "-")) {
                        std.log.err("Output file path is missing.\n", .{});
                        std.log.err("Usage: mini-zig -- -o output.zig [options] input.zig\n", .{});
                        return error.OutputFileMissing;
                    }
                    options.output = output;
                }
                continue;
            } else if (std.mem.eql(u8, arg, "-d") or std.mem.eql(u8, arg, "--documents")) {
                options.keep_doc_comments = true;
                continue;
            } else if (std.mem.eql(u8, arg, "-s") or std.mem.eql(u8, arg, "--spaces")) {
                options.trim_spaces = true;
                continue;
            } else if (std.mem.startsWith(u8, arg, "-")) {
                std.log.err("Unknown option: {s}\n", .{arg});
                printHelp();
                return error.UnknownOption;
            } else if (!std.mem.eql(u8, args[arg_counter - 1], "-o") and !std.mem.eql(u8, args[arg_counter - 1], "--output")) {
                self.file_path = arg;
                continue;
            }
        }
        if (self.file_path == null) {
            std.log.err("File path is missing.\n", .{});
            printHelp();
            return error.FilepathMissing;
        }

        return options;
    }
};

fn minify(allocator: *std.mem.Allocator, file_path: []const u8, options: Options) !void {
    const file = try std.fs.cwd().openFile(file_path, .{ .mode = .read_write });
    defer file.close();
    const file_size = try file.getEndPos();
    try file.seekTo(0);

    var BufReader = std.io.bufferedReader(file.reader());
    var reader = BufReader.reader();

    const file_content = try reader.readAllAlloc(allocator.*, file_size);
    defer allocator.free(file_content);

    var lines = std.mem.tokenize(u8, file_content, "\n");
    var file_content_minified = std.ArrayList(u8).init(allocator.*);
    defer file_content_minified.deinit();

    while (lines.next()) |line| {
        const trimmed_line = std.mem.trim(u8, line, " \t");
        const is_comment = std.mem.startsWith(u8, trimmed_line, "//");
        const is_doc_comment = std.mem.startsWith(u8, trimmed_line, "///");
        //const line_to_write = if (options.trim_spaces) trimmed_line else line;
        if (!is_comment or (is_doc_comment and options.keep_doc_comments)) {
            if (is_doc_comment and options.keep_doc_comments) {
                try file_content_minified.appendSlice(line);
                try file_content_minified.append('\n');
            } else {
                const maybe_comment_pos = std.mem.indexOf(u8, line, "//");
                if (maybe_comment_pos) |comment_pos| {
                    try file_content_minified.appendSlice(line[0..comment_pos]);
                    try file_content_minified.append('\n');
                } else {
                    try file_content_minified.appendSlice(line);
                    try file_content_minified.append('\n');
                }
            }
        }
    }
    const file_content_minified_str = file_content_minified.items;
    if (options.output) |output| {
        const output_file = try std.fs.cwd().createFile(output, .{ .truncate = true });
        defer output_file.close();
        const output_file_writer = output_file.writer();
        try output_file_writer.writeAll(file_content_minified_str);
        std.log.info("File minified and saved to {s}\n", .{output});
        return;
    } else {
        try file.seekTo(0);
        try file.writeAll(file_content_minified_str);
        try file.setEndPos(file_content_minified.items.len);
        std.log.info("File minified and saved to {s}\n", .{file_path});
        return;
    }
}

pub fn main() !void {
    const startTime = std.time.milliTimestamp();
    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();
    var allocator = arena_allocator.allocator();

    var cli = try Cli.init(&allocator);
    defer cli.deinit();
    const options = cli.options;
    if (options.help) {
        printHelp();
        return;
    }

    const file_path = cli.file_path.?;
    _ = try minify(&allocator, file_path, options);
    const endTime = std.time.milliTimestamp();
    std.debug.print("Time taken: {} ms\n", .{endTime - startTime});
}
