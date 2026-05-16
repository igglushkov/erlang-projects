-module(iotserv_db).
-include("iot_device.hrl").
-export([create_tables/1, close_tables/0, add_device/1, lookup_device_id/1]).
-export([restore_backup/0]).

create_tables(FileName) ->
    ets:new(iotDeviceRam, [named_table, {keypos, #iot_device.id}]),
    dets:open_file(iotDeviceDisk, [{file, FileName}, {keypos, #iot_device.id}]).

close_tables() ->
    ets:delete(iotDeviceRam),
    dets:close(iotDeviceDisk).

add_device(#iot_device{} = Device) ->
    ets:insert(iotDeviceRam, Device),
    dets:insert(iotDeviceDisk, Device).

lookup_device_id(DeviceId) ->
    case ets:lookup(iotDeviceRam, DeviceId) of
        [Device] -> {ok, Device};
        []       -> {error, instance}
    end.

restore_backup() ->
    Insert = fun(#iot_device{} = Device) ->
        ets:insert(iotDeviceRam, Device),
        continue
        end,
    dets:traverse(iotDeviceDisk, Insert).