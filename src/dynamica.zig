const std = @import("std");
const iface = @import("interface.zig");
const dyn = @import("dyn.zig");
const vtable = @import("vtable.zig");

pub const Interface = iface.Interface;
pub const Dyn = dyn.Dyn;
pub const MakeInterface = iface.MakeInterface;
pub const printVTable = vtable.printVTable;
pub const iCall = dyn.iCall;
