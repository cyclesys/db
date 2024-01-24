const std = @import("std");
const cy = @import("cycle");
const rdb = @cImport(@cInclude("rocksdb/c.h"));
const scm = @import("scm.zig");

pub fn main() !void {
    const allocator = std.heap.c_allocator;

    const index = cy.obj.Index(.{scm.cmd});
    const Store = cy.obj.Store(index);

    var store = Store.init(allocator);
    defer store.deinit();

    var reader, var writer = try cy.init(allocator, .{
        .index = index.infos,
        .source = scm.src,
        .render = index.ids,
    });
    defer {
        reader.deinit();
        writer.deinit();
    }

    while (try reader.read()) |msg| {
        switch (msg.tag()) {
            .RenderContextObject => {
                const data = msg.value(.RenderContextObject);
                const id = data.field(.id);
                _ = id;

                const context = data.field(.context);

                switch (context.tag()) {
                    .render => {
                        const render_id = context.value(.render);
                        if (render_id == cy.ui.root_id) {}
                    },
                    .data => {
                        const object_id = context.value(.data);
                        _ = object_id;
                    },
                }
            },
            .RenderDataObject => {
                const id = msg.value(.RenderDataObject);
                _ = id;
            },
        }
    }

    const opts = rdb.rocksdb_options_create();
    defer rdb.rocksdb_options_destroy(opts);

    rdb.rocksdb_options_set_compression(opts, rdb.rocksdb_zstd_compression);
    rdb.rocksdb_options_set_bottommost_compression(opts, rdb.rocksdb_zstd_compression);
    rdb.rocksdb_options_set_compaction_style(opts, rdb.rocksdb_level_compaction);

    const db = rdb.rocksdb_open_for_read_only();
    _ = db;
}
