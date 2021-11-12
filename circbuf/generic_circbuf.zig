const std = @import("std");
const testing = std.testing;

const CircBufError = error{
    InvalidParam,
    Empty,
};

fn CircBuf(comptime T: type) type {
    return struct {
        head: usize = 0,
        tail: usize = 0,
        buf: [*]T = null,
        buf_len: usize = 0,

        pub fn init(buf: [*]T, buf_len: usize) CircBuf(T) {
            std.debug.assert(buf_len != 0);
            return CircBuf(T){ .buf = buf, .buf_len = buf_len };
        }

        pub fn push(self: *CircBuf(T), data: T) void {
            self.buf[self.head] = data;
            self.incHead();
            if (self.head == self.tail) {
                self.incTail();
            }
        }

        fn incTail(self: *CircBuf(T)) void {
            self.tail = (self.tail + 1) % self.buf_len;
        }

        fn incHead(self: *CircBuf(T)) void {
            self.head = (self.head + 1) % self.buf_len;
        }

        pub fn pop(self: *CircBuf(T)) CircBufError!T {
            if (self.empty()) {
                return CircBufError.Empty;
            }
            const data: T = self.buf[self.tail];
            self.incTail();
            return data;
        }

        pub fn empty(self: CircBuf(T)) bool {
            return self.head == self.tail;
        }

        pub fn full(self: CircBuf(T)) bool {
            if (self.tail == 0) {
                return (self.tail == 0) and (self.head == self.buf_len - 1);
            }
            return self.head == self.tail - 1;
        }
    };
}

test "circ buf init sets values" {
    var data: [256]f16 = undefined;
    const cb = CircBuf(@TypeOf(data[0])).init(&data, data.len);
    try testing.expect(cb.head == 0);
    try testing.expect(cb.tail == 0);
    try testing.expect(cb.buf == &data);
    try testing.expect(cb.buf_len == data.len);
}

test "circ buf push adds a byte" {
    var data: [5]u8 = undefined;

    var cb = CircBuf(@TypeOf(data[0])).init(&data, data.len);
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
    var data: [5]u16 = undefined;
    var cb = CircBuf(@TypeOf(data[0])).init(&data, data.len);
    if (cb.pop()) |datum| {
        _ = datum;
        unreachable;
    } else |err| {
        try testing.expect(err == CircBufError.Empty);
    }

    cb.push(2000);
    try testing.expect(cb.head == 1);
    try testing.expect(cb.tail == 0);

    const datum = cb.pop() catch 0;

    try testing.expect(datum == 2000);
    try testing.expect(cb.head == 1);
    try testing.expect(cb.tail == 1);
    try testing.expect(cb.empty());

    cb.push(3000);
    cb.push(4000);
    cb.push(5000);
    cb.push(6000);

    try testing.expect(cb.full());
    try testing.expect(cb.head == 0);
    try testing.expect(cb.tail == 1);

    const boop = [_]u16{ 3000, 4000, 5000, 6000 };

    for (boop) |x| {
        const b = cb.pop() catch 0;
        try testing.expect(b == x);
    }

    try testing.expect(cb.empty());
    try testing.expect(cb.head == 0);
    try testing.expect(cb.tail == 0);
}
