%% @doc <code>iotserv</code> provides API functions for managing <code>iot_devices</code>.

-module(iotserv).
-export([start_link/0, stop/0]).
-export([add/5, delete/1, lookup/1, change/3]).
-export([init/1, terminate/2, handle_call/3, handle_cast/2]).
-behaviour(gen_server).

-include("iot_device.hrl").

%% Exported Client Functions
%% Operation & Maintenance API

%% @doc Starts the server.

-spec start_link() -> {ok, Pid :: pid()} | {error, _Reason}.

start_link() ->
    FilePath = config_reader:read_config("priv/config.json"),
    gen_server:start_link({local, ?MODULE}, ?MODULE, FilePath, []).

%% @doc Stops the server.

-spec stop() -> ok.

stop() ->
    gen_server:cast(?MODULE, stop).

%% Customer Sevices API

%% @doc Adding new device to the database.

-spec add(
    Id :: id(),
    Name :: name(),
    Address :: address(),
    Tempature :: tempature(),
    Indicators :: indicators()
) -> ok.

add(Id, Name, Address, Tempature, Indicators) ->
    gen_server:call(?MODULE, {add, Id, Name, Address, Tempature, Indicators}).

%% @doc Lookup device by id.

-spec lookup(Id :: id()) -> {ok, #iot_device{}} | {error, instance}.

lookup(Id) ->
    gen_server:call(?MODULE, {lookup, Id}).

%% @doc Delete device by id.

-spec delete(Id :: id()) -> ok | {error, _Reason}.

delete(Id) ->
    gen_server:call(?MODULE, {delete, Id}).

%% @doc Change device property.

-spec change(Id :: id(), Property :: dev_property(), Value :: term()) ->
    ok | {error, instance} | {error, invalid_property}.

change(Id, Property, Value) when ?is_device_property(Property) ->
    gen_server:call(?MODULE, {change, Id, Property, Value}).

%% Callback Functions

%% @private
%% @doc Initializes data tables for storing iot_device data.

init(FilePath) ->
    iotserv_db:create_tables(FilePath),
    {ok, null}.

%% @private
%% @doc Terminates the server. Closes and syncs data tables.

terminate(_Reason, _State) ->
    iotserv_db:close_tables().

%% @private
%% @doc Handles stop cast.

handle_cast(stop, State) ->
    {stop, normal, State}.

%% @private
%% @doc Handles add command call.

handle_call({add, Id, Name, Address, Tempature, Indicators}, _From, State) ->
    Reply = iotserv_db:add_device(#iot_device{
        id = Id,
        name = Name,
        address = Address,
        tempature = Tempature,
        indicators = Indicators
    }),
    {reply, Reply, State};
%% @private
%% @doc Handles lookup command call.

handle_call({lookup, Id}, _From, State) ->
    Reply = iotserv_db:lookup_device(Id),
    {reply, Reply, State};
%% @private
%% @doc Handles delete command call.

handle_call({delete, Id}, _From, State) ->
    Reply = iotserv_db:delete_device(Id),
    {reply, Reply, State};
%% @private
%% @doc Handles change command call.

handle_call({change, Id, Property, Value}, _From, State) ->
    Reply =
        case iotserv_db:lookup_device(Id) of
            {ok, Device} ->
                case Property of
                    name ->
                        iotserv_db:update_device(Device#iot_device{name = Value});
                    address ->
                        iotserv_db:update_device(Device#iot_device{address = Value});
                    tempature ->
                        iotserv_db:update_device(Device#iot_device{tempature = Value});
                    indicators ->
                        iotserv_db:update_device(Device#iot_device{indicators = Value});
                    _Other ->
                        {error, invalid_property}
                end;
            {error, instance} ->
                {error, instance}
        end,
    {reply, Reply, State}.
