const std = @import("std");
const dynamica = @import("dynamica.zig");
const Dyn = dynamica.Dyn;
const MakeInterface = dynamica.MakeInterface;
const iCall = dynamica.iCall;

pub fn PrinterInterfaceFn(selfType: type) type {
    return struct {
        pub fn print(self: *const selfType, val: i32) i32 {
            return iCall("print", self, .{val}, i32);
        }
    };
}
pub const Printer = MakeInterface(PrinterInterfaceFn);

const SumPrinter = struct {
    val: i32,
    pub fn print(self: *SumPrinter, other: i32) i32 {
        std.debug.print("Printing from SumPrinter: {} + {} = {}\n", .{ self.val, other, self.val + other });
        return 7;
    }
};

const MultiplyPrinter = struct {
    val: i32,
    pub fn print(self: *MultiplyPrinter, other: i32) i32 {
        std.debug.print("Printing from MultiplyPrinter: {} * {} = {}\n", .{ self.val, other, self.val * other });
        return 11;
    }
};

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();

    const sumPrinter: SumPrinter = .{ .val = 5 };
    const dynSumPrinter = Dyn(Printer).init(&sumPrinter);

    const multiplyPrinter: MultiplyPrinter = .{ .val = 6 };
    const dynMultiplyPrinter = Dyn(Printer).init(&multiplyPrinter);

    var printers = std.ArrayList(Dyn(Printer)).init(gpa);
    defer printers.deinit();
    try printers.append(dynSumPrinter);
    try printers.append(dynMultiplyPrinter);

    var sum: i32 = 0;
    for (printers.items) |printer| {
        sum += printer.print(4);
        callWithFive(printer);
    }

    std.debug.print("Sum was: {}\n", .{sum});

    dynamica.printVTable(Printer);
}

fn callWithFive(printer: Dyn(Printer)) void {
    _ = printer.print(5);
}
