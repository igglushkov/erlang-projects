%% @doc <code>iotserv_db</code> provides API for CRUD operations with <code>iot_devices</code>.

-module(iotserv_db).
-include("iot_device.hrl").
-export([create_tables/1, close_tables/0, add_device/1, update_device/1, delete_device/1,
        lookup_device/1, restore_backup/0]).

%% @doc Create <code>ets</code> and <code>dets</code> tables. 
%% Restoring backup from <code>dets</code> table if it already exists.

-spec(create_tables(FileName :: [byte()]) ->  _Return | {error, _Reason}).

create_tables(FileName) ->
    ets:new(iotDeviceRam, [named_table, {keypos, #iot_device.id}]),
    dets:open_file(iotDeviceDisk, [{file, FileName}, {keypos, #iot_device.id}]),
    restore_backup().

%% @doc Closing tables with sync.

-spec(close_tables() -> ok | {error, _Reason}).

close_tables() ->
    ets:delete(iotDeviceRam),
    dets:sync(iotDeviceDisk),
    dets:close(iotDeviceDisk).

%% @doc Adds or updates device entry.

-spec(add_device(Device :: #iot_device{}) -> ok | {error, _Reason}).

add_device(#iot_device{} = Device) ->
    update_device(Device).

%% @doc Insert device entry to both <code>ets</code> and <code>dets</code> tables.

-spec(update_device(Device :: #iot_device{}) -> ok | {error, _Reason}).

update_device(#iot_device{} = Device) ->
    ets:insert(iotDeviceRam, Device),
    dets:insert(iotDeviceDisk, Device).

%% @doc Delete device from tables.

-spec(delete_device(Id :: id()) -> ok | {error, _Reason}).

delete_device(Id) ->
    ets:delete(iotDeviceRam, Id),
    dets:delete(iotDeviceDisk, Id).

%% @doc Lookup device by id.

-spec(lookup_device(Id :: id()) -> {ok, Device :: #iot_device{}} | {error, instance}).

lookup_device(Id) ->
    case ets:lookup(iotDeviceRam, Id) of
        [Device] -> {ok, Device};
        []       -> {error, instance}
    end.

%% @doc Restoring backup data from <code>dets</code> table.

-spec(restore_backup() -> _Return | {error, _Reason}).

restore_backup() ->
    Insert = fun(#iot_device{} = Device) ->
        ets:insert(iotDeviceRam, Device),
        continue
        end,
    dets:traverse(iotDeviceDisk, Insert).
