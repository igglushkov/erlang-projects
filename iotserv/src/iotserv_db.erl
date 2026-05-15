-module(iotserv_db).
-include("iot_device.hrl").
-export([create_tables/1, close_tables/0]).

create_tables(FileName) ->
    ets:new(iotDeviceRam, [named_table, {keypos, #iot_device.id}]),
    dets:open_file(iotDeviceDisk, [{file, FileName}, {keypos, #iot_device.id}]).

close_tables() ->
    ets:delete(iotDeviceRam),
    dets:close(iotDeviceDisk).