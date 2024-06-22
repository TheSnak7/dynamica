const std = @import("std");

fn CreateVTable(interface: type) type {
    const typeInfo = @typeInfo(interface);
    const decls = typeInfo.Struct.decls;
    //Two extra fields: One for the runtimeTypeInfo and one for the deinit function
    var fields: [2 + decls.len]std.builtin.Type.StructField = undefined;

    fields[0] = .{
        .name = "runtimeTypeInfo",
        .type = i32,
        .default_value = null,
        .is_comptime = false,
        .alignment = 4,
    };

    fields[1] = .{
        .name = "vDeinit",
        .type = *const @TypeOf(emptyDeinit),
        .default_value = null,
        .is_comptime = false,
        .alignment = 4,
    };

    inline for (fields[2..fields.len], 2..) |_, idx| {
        fields[idx] = .{
            .name = decls[idx - 2].name,
            .type = *const @TypeOf(@field(interface, decls[idx - 2].name)),
            .default_value = null,
            .is_comptime = false,
            .alignment = 0,
        };
    }

    return @Type(.{
        .Struct = .{
            .layout = .auto,
            .fields = fields[0..],
            .decls = &.{},
            .is_tuple = false,
        },
    });
}

fn LinkVTable(implementation: type, vTableType: type) vTableType {
    const vTypeInfo = @typeInfo(vTableType);
    const fields = vTypeInfo.Struct.fields;

    var implVtable: vTableType = undefined;

    inline for (fields) |field| {
        if (std.mem.eql(u8, field.name, "runtimeTypeInfo")) {
            //TODO: Add runtime type information
            @field(implVtable, "runtimeTypeInfo") = 0;
        } else if (std.mem.eql(u8, field.name, "vDeinit")) {
            @field(implVtable, "vDeinit") = &emptyDeinit;
        } else {
            @field(implVtable, field.name) = @alignCast(@ptrCast(@constCast(&@field(implementation, field.name))));
        }
    }
    return implVtable;
}

fn CreateDynRef(value: anytype, interface: type, vTable: anytype) Dyn(interface) {
    return .{ .this = @ptrCast(@constCast(value)), .v = vTable };
}

pub fn Dyn(interface: type) type {
    const vTableType = CreateVTable(interface);

    return struct {
        this: *anyopaque,
        v: *const vTableType,

        pub fn init(value: anytype) @This() {
            const underlyingType = std.meta.Child(@TypeOf(value));

            const globalWrapper = struct {
                pub const vTableImpl = LinkVTable(underlyingType, vTableType);
            };
            return CreateDynRef(value, interface, &globalWrapper.vTableImpl);
        }
    };
}

pub fn implementWith(argumentTuple: anytype) noreturn {
    _ = argumentTuple;
    std.debug.panic("Virtual interace method panicked. Has to be implemented and not called directly", .{});
    unreachable;
}

fn emptyDeinit(this: *anyopaque, allocator: std.mem.Allocator) void {
    _ = this;
    _ = allocator;
}

pub fn dumpVTable(interface: type, vtable: CreateVTable(interface)) void {
    std.debug.print("Printing Vtable for {s}:\n", .{@typeName(interface)});
    const fields = std.meta.fields(@TypeOf(vtable));
    inline for (fields) |field| {
        std.debug.print("    Field: {s} : {s} : with size {} and offset {}\n", .{ field.name, @typeName(field.type), @sizeOf(field.type), @offsetOf(@TypeOf(vtable), field.name) });
    }
    std.debug.print("Total size: {}\n", .{@sizeOf(@TypeOf(vtable))});
}
