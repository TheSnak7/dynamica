const std = @import("std");
const Interface = @import("dynamica.zig").Interface;

pub fn CreateVTableType(interface: type) type {
    const decls = std.meta.declarations(interface);

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

pub fn LinkVTable(implementation: type, interface: Interface) interface.vTableType {
    const fields = std.meta.fields(interface.vTableType);

    var implVtable: interface.vTableType = undefined;

    inline for (fields) |field| {
        if (std.mem.eql(u8, field.name, "runtimeTypeInfo")) {
            //TODO: Add runtime type information
            @field(implVtable, "runtimeTypeInfo") = 0;
        } else if (std.mem.eql(u8, field.name, "vDeinit")) {
            @field(implVtable, "vDeinit") = &emptyDeinit;
        } else {
            //Verfiy function signatures, safety lost because of the casts
            _ = isFunctionSignatureValid(
                @TypeOf(@field(implVtable, field.name)),
                @TypeOf(@field(implementation, field.name)),
                interface,
                implementation,
            );
            @field(implVtable, field.name) = @ptrCast(@alignCast(@constCast(&@field(implementation, field.name))));
        }
    }
    return implVtable;
}

fn isFunctionSignatureValid(vTableFnPtr: type, implFnObject: type, interface: Interface, implementaion: type) bool {
    const vTableFnTypeInfo = @typeInfo(std.meta.Child(vTableFnPtr));
    const paramsVTableFn = vTableFnTypeInfo.Fn.params;
    const paramsImplFn = @typeInfo(implFnObject).Fn.params;

    //TODO: Verfiy first param
    for (paramsVTableFn[1..], paramsImplFn[1..]) |paramVTab, paramImpl| {
        const paramVTableType = paramVTab.type orelse {
            @compileError("Unknown edge case");
        };
        const paramImplType = paramImpl.type orelse {
            @compileError("Unknown edge case");
        };

        if (paramVTableType != paramImplType) {
            @compileError("Function signature mismatch (ignore first param):\n  Found: " ++ @typeName(std.meta.Child(vTableFnPtr)) ++
                " -------- in interface: " ++ @typeName(interface.interfaceType) ++ "\n" ++
                "  Found: " ++ @typeName(implFnObject) ++ " -------- in implementaion: " ++ @typeName(implementaion));
        }
    }
    return true;
}

fn emptyDeinit(this: *anyopaque, allocator: std.mem.Allocator) void {
    _ = this;
    _ = allocator;
}

pub fn printVTable(interface: Interface) void {
    std.debug.print("Printing Vtable for {s}:\n", .{@typeName(interface.interfaceType)});
    const fields = std.meta.fields(interface.vTableType);
    inline for (fields) |field| {
        std.debug.print("    Field: {s} : {s} : with size {} and offset {}\n", .{ field.name, @typeName(field.type), @sizeOf(field.type), @offsetOf(interface.vTableType, field.name) });
    }
    std.debug.print("Total size: {}\n", .{@sizeOf(interface.vTableType)});
}
