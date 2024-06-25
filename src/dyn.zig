const std = @import("std");
const dynamica = @import("dynamica.zig");
const vtable = @import("vtable.zig");
const Interface = dynamica.Interface;
const LinkVTable = vtable.LinkVTable;

pub fn Dyn(interface: Interface) type {
    return struct {
        pub usingnamespace interface.interfaceFn(Dyn(interface));

        this: *anyopaque,
        vTable: *const interface.vTableType,

        pub fn init(value: anytype) @This() {
            const underlyingType = std.meta.Child(@TypeOf(value));

            const globaVTableContainer = struct {
                pub const vTableImpl = LinkVTable(underlyingType, interface);
            };
            return CreateDynObject(value, interface, &globaVTableContainer.vTableImpl);
        }
    };
}

pub fn CreateDynObject(value: anytype, interface: Interface, vTable: anytype) Dyn(interface) {
    return .{ .this = @ptrCast(@constCast(value)), .vTable = vTable };
}

pub inline fn iCall(comptime funcName: []const u8, self: anytype, argumentTuple: anytype) void {
    @call(.auto, @field(self.vTable.*, funcName), .{self.this} ++ argumentTuple);
}
