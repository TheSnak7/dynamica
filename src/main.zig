const std = @import("std");
const dynamica = @import("dynamica.zig");
const Dyn = dynamica.Dyn;
const vSelf = dynamica.vSelf;
const implementWith = dynamica.implementWith;

const Printer = struct {
    pub fn print(this: *anyopaque, message: []const u8) void {
        implementWith(.{ this, message });
    }
};

const ConsolePrinter = struct {
    dummy: i32,
    pub fn print(self: *ConsolePrinter, message: []const u8) void {
        std.debug.print("Printing with val: {s} and {}\n", .{ message, self.dummy });
    }
};

const HelloPrinter = struct {
    fun: i32,
    pub fn print(self: *HelloPrinter, message: []const u8) void {
        std.debug.print("Hello {s} with {} hugs\n", .{ message, self.fun });
    }
};

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);
    const gpa = general_purpose_allocator.allocator();

    const testTPrinter: ConsolePrinter = .{ .dummy = 5 };
    const dynTPrinter = Dyn(Printer).init(&testTPrinter);

    const testHPrinter: HelloPrinter = .{ .fun = 6 };
    const dynHPrinter = Dyn(Printer).init(&testHPrinter);

    var printers = std.ArrayList(Dyn(Printer)).init(gpa);
    defer printers.deinit();
    try printers.append(dynTPrinter);
    try printers.append(dynHPrinter);

    for (printers.items) |printer| {
        printer.v.print(printer.this, "Info");
    }

    dynamica.dumpVTable(Printer, dynTPrinter.v.*);
}
