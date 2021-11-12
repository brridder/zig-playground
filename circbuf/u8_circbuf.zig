const std = @import("std");
const testing = std.testing;

const CircBuf = struct {
    head: usize = 0,
    tail: usize = 0,
    buf: [*]u8 = null,
    buf_len: usize = 0,

    const Error = error{
        InvalidParam,
        Empty,
    };

    pub fn init(buf: [*]u8, buf_len: usize) CircBuf {
        std.debug.assert(buf_len != 0);
        return CircBuf{
            .head = 0,
            .tail = 0,
            .buf = buf,
            .buf_len = buf_len,
        };
    }

    pub fn push(self: *CircBuf, data: u8) void {
        self.buf[self.head] = data;
        self.incHead();
        if (self.head == self.tail) {
            self.incTail();
        }
    }

    fn incTail(self: *CircBuf) void {
        self.tail = (self.tail + 1) % self.buf_len;
    }

    fn incHead(self: *CircBuf) void {
        self.head = (self.head + 1) % self.buf_len;
    }

    pub fn pop(self: *CircBuf) CircBuf.Error!u8 {
        if (self.empty()) {
            return CircBuf.Error.Empty;
        }
        const data: u8 = self.buf[self.tail];
        self.incTail();
        return data;
    }

    pub fn empty(self: CircBuf) bool {
        return self.head == self.tail;
    }

    pub fn full(self: *CircBuf) bool {
        if (self.tail == 0) {
            return (self.tail == 0) and (self.head == self.buf_len - 1);
        }
        return self.head == self.tail - 1;
    }
};

test "circ buf init sets values" {
    var data: [256]u8 = undefined;
    const cb = CircBuf.init(&data, data.len);
    try testing.expect(cb.head == 0);
    try testing.expect(cb.tail == 0);
    try testing.expect(cb.buf == &data);
    try testing.expect(cb.buf_len == data.len);
}

test "circ buf push adds a byte" {
    var data: [5]u8 = undefined;

    var cb = CircBuf.init(&data, data.len);
    try testing.expect(cb.head == 0);
    try testing.expect(cb.empty());
    try testing.expect(!cb.full());

    cb.push(10);
    try testing.expect(cb.head == 1);
    try testing.expect(cb.tail == 0);
    try testing.expect(cb.buf[0] == 10);
    try testing.expect(!cb.empty());
    try testing.expect(!cb.full());
    cb.push(20);
    try testing.expect(cb.head == 2);
    try testing.expect(cb.tail == 0);
    try testing.expect(cb.buf[1] == 20);
    try testing.expect(!cb.empty());
    try testing.expect(!cb.full());
    cb.push(30);
    try testing.expect(cb.head == 3);
    try testing.expect(cb.tail == 0);
    try testing.expect(cb.buf[2] == 30);
    try testing.expect(!cb.empty());
    try testing.expect(!cb.full());
    cb.push(40);
    try testing.expect(cb.head == 4);
    try testing.expect(cb.tail == 0);
    try testing.expect(cb.buf[3] == 40);
    try testing.expect(!cb.empty());
    try testing.expect(cb.full());

    // Loops around, now needs to bump tail since it dropped a datum
    cb.push(50);
    try testing.expect(cb.head == 0);
    try testing.expect(cb.tail == 1);
    try testing.expect(cb.buf[4] == 50);
    try testing.expect(!cb.empty());
    try testing.expect(cb.full());

    cb.push(60);
    try testing.expect(cb.head == 1);
    try testing.expect(cb.tail == 2);
    try testing.expect(cb.buf[0] == 60);
    try testing.expect(!cb.empty());
    try testing.expect(cb.full());
}

test "circbuf pop returns a datum" {
    var data: [5]u8 = undefined;
    var cb = CircBuf.init(&data, data.len);
    if (cb.pop()) |byte| {
        _ = byte;
        unreachable;
    } else |err| {
        try testing.expect(err == CircBuf.Error.Empty);
    }

    cb.push(100);
    try testing.expect(cb.head == 1);
    try testing.expect(cb.tail == 0);

    const datum = cb.pop() catch 0;

    try testing.expect(datum == 100);
    try testing.expect(cb.head == 1);
    try testing.expect(cb.tail == 1);
    try testing.expect(cb.empty());

    cb.push(20);
    cb.push(30);
    cb.push(40);
    cb.push(50);

    try testing.expect(cb.full());
    try testing.expect(cb.head == 0);
    try testing.expect(cb.tail == 1);

    const boop = [_]u8{ 20, 30, 40, 50 };

    for (boop) |x| {
        const b = cb.pop() catch 0;
        try testing.expect(b == x);
    }

    try testing.expect(cb.empty());
    try testing.expect(cb.head == 0);
    try testing.expect(cb.tail == 0);
}
