-module(iotserv).
-export([start_link/0, start_link/1, stop/0]).
-export([add/5, delete/1, lookup/1]).
-export([init/1, terminate/2, handle_call/3, handle_cast/2]).
-behaviour(gen_server).

-include("iot_device.hrl").

%% Exported Client Functions
%% Operation & Maintenance API

start_link() ->
    start_link("IotDevicesDb").

start_link(FileName) ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, FileName, []).

stop() ->
    gen_server:cast(?MODULE, stop).

%% Customer Sevices API

add(Id, Name, Address, Tempature, Indicators) ->
    gen_server:call(?MODULE, {add, Id, Name, Address, Tempature, Indicators}).

lookup(Id) ->
    gen_server:call(?MODULE, {lookup, Id}).

delete(Id) ->
    gen_server:call(?MODULE, {delete, Id}).

%% Callback Functions

init(FileName) ->
    iotserv_db:create_tables(FileName),
    iotserv_db:restore_backup(),
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
    {reply, Reply, State}.