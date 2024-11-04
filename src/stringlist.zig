const std = @import("std");


pub const StringList = struct {
    alloc:std.mem.Allocator,
    list:std.ArrayList([]const u8),

    /// Build a new StringList . Internally creates an ArrayList upon the chosen allocator.
    pub fn init(alloc:std.mem.Allocator) StringList {
        return StringList {
            .alloc = alloc,
            .list = std.ArrayList([]const u8).init(alloc),
        };
    }

    /// Invalidate the entire StringList and its poitners, including itself.
    /// The StringList may no longer be used.
    pub fn destroy(self:*StringList) void {
        for(self.list.items) |line| {
            self.alloc.free(line);
        }
        self.list.deinit();
    }

    pub fn append(self:*StringList, data:[]const u8) !void {
        const val_p = try self.alloc.alloc(u8, data.len);
        @memcpy(val_p, data);

        try self.list.append(val_p);
    }

    pub fn extend(self:*StringList, source:*StringList) !void {
        for(source.list.items) |item| {
            try self.append(item);
        }
    }

    /// Invlaidate all the contents of the struct, but not itself.
    /// After clearing, the StringList can continue to accumulate new data.
    pub fn clear(self:*StringList) void {
        while(self.list.popOrNull() ) |item| {
            self.alloc.free(item);
        }
    }

    pub fn items(self:*const StringList) [][]const u8 {
        return self.list.items;
    }

    /// From an input StringList , extract items containing (searchterm)
    ///  and add it to the current StringList
    pub fn addStringsWhichHave(self:*StringList, searchterm:[]const u8, from_list:StringList) !void {
        for(from_list.list.items) |token| {
            if(std.mem.containsAtLeast(u8, token, 1, searchterm)) {
                try self.append(token);
            }
        }
    }

    pub fn totalSize(self:*StringList) usize {
        var byte_count:usize = 0;
        for(self.list.items) |item| {
            byte_count += item.len;
        }
        return byte_count;
    }

    pub fn itemCount(self:*const StringList) usize {
        return self.list.items.len;
    }

    /// Combine all string tokens joined by specified joiner,
    ///  into provided backing buffer, and return the _slice_
    ///  of the resulting data.
    pub fn join(self:*const StringList, joiner:[]const u8, buffer:[]u8) []u8 {
        var i:usize = 0;
        // Question to self : why not accumulate in an ArrayList, and return an allocated item?
        // (replace `buffer` with an explicit allocator)

        for(self.list.items, 0..) |item,n| {
            i += _copy_at(item, i, buffer);
            if(n < self.list.items.len-1) {
                i += _copy_at(joiner, i, buffer);
            }
        }

        return buffer[0..i];
    }


    pub fn loadLinesContaining(self:*StringList, needle:[]const u8, source:*const StringList) !void {
        for(source.list.items) |item| {
            if(std.mem.containsAtLeast(u8, item, 1, needle) ) {
                try self.append(item);
            }
        }
    }

};


fn _copy_at(source:[]const u8, start_idx:usize, buffer:[]u8) usize {
    var i:usize = start_idx;
    for(0..source.len) |j| {
        buffer[i] = source[j];
        i += 1;
    }

    return source.len;
}

test {
    var sr = StringList.init(std.testing.allocator);
    defer sr.destroy();

    try sr.append("Hi");
    try sr.append("Bye");

    // We need a backing buffer to perform the accumulation in
    var buff = [_]u8{undefined}**32;
    // but we get the specific non-sentinel slice if we need it
    const slice = sr.join(" ", &buff);
    // because the string literal is not sentinel-terminated but length-terminated (tbc?).
    try std.testing.expectEqualStrings("Hi Bye", slice);
}

test {
    var sr = StringList.init(std.testing.allocator);
    defer sr.destroy();

    try sr.append("Alex");
    try sr.append("Bub");
    try sr.append("Charle");

    var sr_le = StringList.init(std.testing.allocator);
    defer sr_le.destroy();
    try sr_le.loadLinesContaining("le", &sr);

    var buff = [_]u8{undefined}**32;
    const slice = sr_le.join(" ", &buff);
    try std.testing.expectEqualStrings("Alex Charle", slice);
}
