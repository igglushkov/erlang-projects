-module(client).

-include("include/event_info.hrl").

-export([start/1, init/0, subscribe/2, add/5]).

-define(TIMEOUT, 2000).

start(Name) ->
    Pid = spawn(?MODULE, init, []),
    register(Name, Pid),
    {ok, Name, Pid}.

-spec subscribe(ClientName :: atom(), ServerName :: atom()) -> {ok, reference()} | {error, atom()}.

subscribe(ClientName, ServerName) ->
    ServerName ! {subscribe, self(), ClientName},
    receive
        ok ->
            MonitorRef = erlang:monitor(process, ServerName),
            io:format("client now monitor procces ~p under ref ~p~n", [ServerName, MonitorRef]),
            {ok, MonitorRef};
        {error, Reason} ->
            {error, Reason}
    after ?TIMEOUT ->
        {error, timeout}
    end.

add(ClientName, ServerName, EventName, Description, Timeout) ->
    EventInfo = #event_info{
        client_name = ClientName, event_name = EventName,
        description = Description, timeout = Timeout},
    ServerName ! {add, self(), EventInfo},
    receive
        {ok, EventPid, EventId} -> {ok, EventPid, EventId};
        {error, Reason} -> {error, Reason}
    after ?TIMEOUT ->
        {error, timeout}
    end.

init() ->
    loop(),
    ok.

loop() ->
    receive
        Msg -> 
            Msg,
            loop()
    end.