-module(iotserv_db).
-include("iot_device.hrl").
-export([create_tables/1, close_tables/0, add_device/1, update_device/1, delete_device/1,
        lookup_device/1, restore_backup/0]).

create_tables(FileName) ->
    ets:new(iotDeviceRam, [named_table, {keypos, #iot_device.id}]),
    dets:open_file(iotDeviceDisk, [{file, FileName}, {keypos, #iot_device.id}]),
    restore_backup().

close_tables() ->
    ets:delete(iotDeviceRam),
    dets:sync(iotDeviceDisk),
    dets:close(iotDeviceDisk).

add_device(#iot_device{} = Device) ->
    update_device(Device).

update_device(#iot_device{} = Device) ->
    ets:insert(iotDeviceRam, Device),
    dets:insert(iotDeviceDisk, Device),
    ok.

delete_device(Id) ->
    ets:delete(iotDeviceRam, Id),
    dets:delete(iotDeviceDisk, Id).

lookup_device(Id) ->
    case ets:lookup(iotDeviceRam, Id) of
        [Device] -> {ok, Device};
        []       -> {error, instance}
    end.

restore_backup() ->
    Insert = fun(#iot_device{} = Device) ->
        ets:insert(iotDeviceRam, Device),
        continue
        end,
    dets:traverse(iotDeviceDisk, Insert).