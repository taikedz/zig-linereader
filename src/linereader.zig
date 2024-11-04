const std = @import("std");
const stringlist = @import("./stringlist.zig");


pub fn readFileLines(alloc:std.mem.Allocator, path:[]const u8) !stringlist.StringList {
    var fh = try std.fs.openFileAbsolute(path, .{});
    defer fh.close();

    var line_buf_t = std.ArrayList(u8).init(alloc);
    defer line_buf_t.deinit();
    var buf_reader_t = std.io.bufferedReader(fh.reader());
    var reader = buf_reader_t.reader();

    var lines = stringlist.StringList.init(alloc);

    while(reader.streamUntilDelimiter(line_buf_t.writer(), '\n', null)) {
        try lines.append(line_buf_t.items);
        line_buf_t.clearRetainingCapacity();
    } else |err| switch(err) {
        error.EndOfStream => {
            try lines.append(line_buf_t.items);
            return lines;
        },
        else => return err,
    }
}

test {
    var lines = try readFileLines(std.testing.allocator, "/etc/os-release");
    defer lines.destroy();

    var subsection = stringlist.StringList.init(std.testing.allocator);
    defer subsection.destroy();

    try subsection.loadLinesContaining("NAME", &lines);
    try std.testing.expect(subsection.itemCount() >= 1);
    for(subsection.items()) |line| {
        std.debug.print("1--> {s}\n", .{line});
    }

    subsection.clear();
    try std.testing.expect(subsection.itemCount() == 0);

    try subsection.loadLinesContaining("VERSION_ID", &lines);
    try std.testing.expect(subsection.itemCount() == 1);
    for(subsection.items()) |line| {
        std.debug.print("2--> {s}\n", .{line});
    }
}
