const std = @import("std");
const stringlist = @import("./stringlist.zig");


pub fn readFileLines(alloc:std.mem.Allocator, path:[]const u8) !stringlist.StringList {
    var fh = try std.fs.openFileAbsolute(path, .{}); // FIXME allow relative path
    defer fh.close();

    var line_buf_t = std.ArrayList(u8).init(alloc);
    defer line_buf_t.deinit();
    var buf_reader_t = std.io.bufferedReader(fh.reader());
    var reader = buf_reader_t.reader();

    var lines = stringlist.StringList.init(alloc);

    while(reader.streamUntilDelimiter(line_buf_t.writer(), '\n', null)) { // FIXME: can use []u8 delimiter?
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

pub fn writeFileLines(source:*const stringlist.StringList, path:[]const u8, linesep:?[]const u8) !void {
    // TODO: write the lines
}

test {
    const ut_file = "./tmp-unittest-linereader";

    var test_lines = stringlist.StringList.init(std.testing.allocator);
    try test_lines.append("THIS=hello");
    try test_lines.append("THAT=bye bye");
    try test_lines.append("THAT_TOO=ciao");
    try writeFileLines(&test_lines, ut_file, "\n");

    var lines = try readFileLines(std.testing.allocator, ut_file);
    defer lines.destroy();

    var subsection = stringlist.StringList.init(std.testing.allocator);
    defer subsection.destroy();

    try subsection.loadLinesContaining("THIS", &lines);
    try std.testing.expect(subsection.itemCount() == 1);

    subsection.clear();
    try std.testing.expect(subsection.itemCount() == 0);

    try subsection.loadLinesContaining("THAT", &lines);
    try std.testing.expect(subsection.itemCount() == 2);

    // TODO: remove ut_file
}
