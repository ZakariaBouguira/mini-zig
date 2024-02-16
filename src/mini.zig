const std = @import("std");

pub fn main() !void {
    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();
    const allocator = arena_allocator.allocator();

    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();

    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    var file_path: []const u8 = "";

    if (args.len < 2) {
        try stdout.writeAll("\n\nEnter the zig file to minify: ");
        file_path = try stdin.readUntilDelimiterOrEofAlloc(std.heap.page_allocator, '\n', 1000) orelse {
            std.debug.print("\nFailed to read input.\n", .{});
            return;
        };
    } else {
        file_path = args[1];
    }

    std.debug.print("\nFile path: {s}\n", .{file_path});

    const file = try std.fs.cwd().openFile(file_path, .{ .mode = .read_write });
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var reader = buf_reader.reader();

    // Read the file into memory
    const file_content = try reader.readAllAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(file_content);

    var lines = std.mem.tokenize(u8, file_content, "\n");
    var file_content_new = std.ArrayList(u8).init(allocator);
    defer file_content_new.deinit();

    var line_number: u32 = 0;
    while (lines.next()) |line| : (line_number += 1) {
        if (!std.mem.startsWith(u8, std.mem.trimLeft(u8, line, " \t"), "//")) {
            try file_content_new.appendSlice(line);
            try file_content_new.append('\n');
        }
    }
    try file.seekTo(0);
    try file.writeAll(file_content_new.items);
    try file.setEndPos(file_content_new.items.len);
}
