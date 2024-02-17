const std = @import("std");

pub fn main() !void {
    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();
    const allocator = arena_allocator.allocator();

    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var file_path: []const u8 = "";
    var keep_doc_comments = false;

    if (args.len < 2) {
        try stdout.writeAll("\nEnter the zig file to minify: ");
        file_path = try stdin.readUntilDelimiterOrEofAlloc(allocator, '\n', 1000) orelse {
            std.debug.print("\nFailed to read input.\n", .{});
            return;
        };
        file_path = std.mem.trimRight(u8, file_path, "\n");
    } else {
        for (args[1..]) |arg| {
            if (std.mem.eql(u8, arg, "-keep-doc")) {
                keep_doc_comments = true;
            } else {
                file_path = arg;
            }
        }
    }

    std.debug.print("\nFile path: {s}, Keep Doc Comments: {}\n", .{ file_path, keep_doc_comments });

    const file = try std.fs.cwd().openFile(file_path, .{ .mode = .read_write });
    defer file.close();

    try file.seekTo(0);

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
        const trimmed_line = std.mem.trim(u8, line, " \t");
        const is_comment = std.mem.startsWith(u8, trimmed_line, "//");
        const is_doc_comment = std.mem.startsWith(u8, trimmed_line, "///");
        if (!is_comment or (is_doc_comment and keep_doc_comments)) {
            if (is_doc_comment and keep_doc_comments) {
                try file_content_new.appendSlice(line);
                try file_content_new.append('\n');
            } else {
                const maybe_comment_pos = std.mem.indexOf(u8, line, "//");
                if (maybe_comment_pos) |comment_pos| {
                    try file_content_new.appendSlice(line[0..comment_pos]);
                    try file_content_new.append('\n');
                } else {
                    try file_content_new.appendSlice(line);
                    try file_content_new.append('\n');
                }
            }
        }
    }
    try file.seekTo(0);
    try file.writeAll(file_content_new.items);
    try file.setEndPos(file_content_new.items.len);
}
