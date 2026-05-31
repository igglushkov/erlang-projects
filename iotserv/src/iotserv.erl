-module(iotserv).
-export([start_link/0, stop/0]).
-export([add/5, delete/1, lookup/1, change/3]).
-export([init/1, terminate/2, handle_call/3, handle_cast/2]).
-behaviour(gen_server).

-include("iot_device.hrl").

%% Exported Client Functions
%% Operation & Maintenance API

start_link() ->
    FilePath = config_reader:read_config("priv/config.json"),
    gen_server:start_link({local, ?MODULE}, ?MODULE, FilePath, []).

stop() ->
    gen_server:cast(?MODULE, stop).

%% Customer Sevices API

add(Id, Name, Address, Tempature, Indicators) ->
    gen_server:call(?MODULE, {add, Id, Name, Address, Tempature, Indicators}).

lookup(Id) ->
    gen_server:call(?MODULE, {lookup, Id}).

delete(Id) ->
    gen_server:call(?MODULE, {delete, Id}).

change(Id, Property, Value) when ?is_device_property(Property) ->
    gen_server:call(?MODULE, {change, Id, Property, Value}).

%% Callback Functions

init(FilePath) ->
    iotserv_db:create_tables(FilePath),
    {ok, null}.

terminate(_Reason, _State) ->
    iotserv_db:close_tables().

handle_cast(stop, State) ->
    {stop, normal, State}.

handle_call({add, Id, Name, Address, Tempature, Indicators}, _From, State) ->
    Reply = iotserv_db:add_device(#iot_device{id = Id, 
                                            name = Name, 
                                            address = Address,
                                            tempature = Tempature,
                                            indicators = Indicators}),
    {reply, Reply, State};

handle_call({lookup, Id}, _From, State) ->
    Reply = iotserv_db:lookup_device(Id),
    {reply, Reply, State};

handle_call({delete, Id}, _From, State) ->
    Reply = iotserv_db:delete_device(Id),
    {reply, Reply, State};

handle_call({change, Id, Property, Value}, _From, State) ->
    Reply = case iotserv_db:lookup_device(Id) of
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