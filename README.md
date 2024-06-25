# Dynamica

## Overview

Dynamica is a library that provides a mechanism for dynamic dispatch/ interfaces in Zig. While it's not as ergonomic as an 'interface' keyword, it is still quite easy to create interfaces using Zig's powerful comptime and reflection capabilities.

## Goals

Structural typing-like. Struct should not have to declare that they implement a certain interface, if they implement all of the necessary functions `Dyn(Interface).init(*struct)` will succeed. Furthermore the developer should not write duplicate code, e.g. repeating all function definitions for a VTable type.

## Basic Usage

Define a function with the signature: `pub fn ExampleInterfaceFn(selfType: type) type` which returns a struct with all of the functions of your interface.

Call `const ExampleInteface = MakeInterface(ExampleInterfaceFn)` to get your interface type.

Now `Dyn(ExampleInterface)` returns a dynamic interface object, which can be used as an argument to a function, or initialized an pointer: `Dyn(ExampleInterface).init(&implStruct)`

## Example

```zig
pub fn PrinterInterfaceFn(selfType: type) type {
    return struct {
        pub fn print(self: *const selfType, val: i32) void {
            return iCall("print", self, .{val}, void);
        }
    };
}
pub const Printer = MakeInterface(PrinterInterfaceFn);

const SumPrinter = struct {
    val: i32,
    pub fn print(self: *SumPrinter, other: i32) void {
        std.debug.print("SumPrinter: {} + {} = {}\n", .{ self.val, other, self.val + other });
    }
};

const MultiplyPrinter = struct {
    val: i32,
    pub fn print(self: *MultiplyPrinter, other: i32) void {
        std.debug.print("MultiplyPrinter: {} * {} = {}\n", .{ self.val, other, self.val * other });
    }
};


const sumPrinter: SumPrinter = .{ .val = 5 };
const dynSumPrinter = Dyn(Printer).init(&sumPrinter);

const multiplyPrinter: MultiplyPrinter = .{ .val = 6 };
const dynMultiplyPrinter = Dyn(Printer).init(&multiplyPrinter);

var printers = std.ArrayList(Dyn(Printer)).init(gpa);

for (printers.items) |printer| {
    printer.print(4);
}
```
