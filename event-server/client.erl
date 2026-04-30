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
    ServerName ! {add, self(), ClientName, EventName, Description, Timeout},
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
        {done, EventName, Description} -> 
            io:format("~p ~p is timeout~n", [EventName, Description]),
            loop();
        _ -> loop()
    end.