const std = @import("std");


pub const Lines = struct {
    alloc:std.mem.Allocator,
    list:std.ArrayList([]const u8),

    pub fn init(alloc:std.mem.Allocator) Lines {
        return Lines {
            .alloc = alloc,
            .list = std.ArrayList([]const u8).init(alloc),
        };
    }

    pub fn destroy(self:*Lines) void {
        for(self.list.items) |line| {
            self.alloc.free(line);
        }
        self.list.deinit();
    }

    pub fn append(self:*Lines, data:[]const u8) !void {
        const val_p = try self.alloc.alloc(u8, data.len);
        @memcpy(val_p, data);

        try self.list.append(val_p);
    }

    pub fn clear(self:*Lines) void {
        while(self.list.popOrNull() ) |item| {
            self.alloc.free(item);
        }
    }

    pub fn getLines(self:*const Lines) [][]const u8 {
        return self.list.items;
    }

    pub fn loadLinesWhere(self:*Lines, searchterm:[]const u8, in:Lines) !void {
        for(in.list.items) |line| {
            if(std.mem.containsAtLeast(u8, line, 1, searchterm)) {
                try self.append(line);
            }
        }
    }

};

pub fn readFileLines(alloc:std.mem.Allocator, path:[]const u8) !Lines {
    var fh = try std.fs.openFileAbsolute(path, .{});
    defer fh.close();

    var line_buf_t = std.ArrayList(u8).init(alloc);
    defer line_buf_t.deinit();
    var buf_reader_t = std.io.bufferedReader(fh.reader());
    var reader = buf_reader_t.reader();

    var lines = Lines.init(alloc);

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
    // TODO - standalone unit tests for Lines
    var lines = try readFileLines(std.testing.allocator, "/etc/os-release");
    defer lines.destroy();

    var subsection = Lines.init(std.testing.allocator);
    defer subsection.destroy();

    try subsection.loadLinesWhere("PRETTY", lines);
    for(subsection.getLines()) |line| {
        std.debug.print("1--> {s}\n", .{line});
    }

    subsection.clear();

    try subsection.loadLinesWhere("VERSION_ID", lines);
    for(subsection.getLines()) |line| {
        std.debug.print("2--> {s}\n", .{line});
    }
}
