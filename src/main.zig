const std = @import("std");
const dynamica = @import("dynamica.zig");
const Dyn = dynamica.Dyn;
const MakeInterface = dynamica.MakeInterface;
const iCall = dynamica.iCall;

pub fn PrinterInterfaceFn(selfType: type) type {
    return struct {
        pub fn print(self: *const selfType, val: i32) void {
            return iCall("print", .{ self, val });
        }
    };
}
pub const Printer = MakeInterface(PrinterInterfaceFn);

const SumPrinter = struct {
    val: i32,
    pub fn print(self: *SumPrinter, other: i32) void {
        std.debug.print("Printing from SumPrinter: {} + {} = {}\n", .{ self.val, other, self.val + other });
    }
};

const MultiplyPrinter = struct {
    val: i32,
    pub fn print(self: *MultiplyPrinter, other: i32) void {
        std.debug.print("Printing from SumPrinter: {} * {} = {}\n", .{ self.val, other, self.val * other });
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

    for (printers.items) |printer| {
        printer.print(4);
        callWithFive(printer);
    }

    dynamica.printVTable(Printer);
}

fn callWithFive(printer: Dyn(Printer)) void {
    printer.print(5);
}
