const CreateVTableType = @import("vtable.zig").CreateVTableType;

pub const Interface = struct {
    interfaceFn: fn (comptime type) type,
    interfaceType: type,
    vTableType: type,
};

pub fn MakeInterface(interfaceFn: fn (comptime type) type) Interface {
    return .{
        .interfaceFn = interfaceFn,
        .interfaceType = interfaceFn(anyopaque),
        .vTableType = CreateVTableType(interfaceFn(anyopaque)),
    };
}
