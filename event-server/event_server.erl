-module(event_server).

-export([start/0, init/0]).

start() ->
    Pid = spawn(?MODULE, init, []),
    register(?MODULE, Pid),
    {ok, Pid}.

init() ->
    loop(),
    ok.

loop() ->
    receive
        {subscribe, From, ClientName} -> 
            MonitorRef = erlang:monitor(process, ClientName),
            io:format("event server now monitor procces ~p under ref ~p~n", [ClientName, MonitorRef]),
            From ! ok,
            loop();
        {'DOWN', _Ref, process, Pid, Reason} ->
            io:format("Event Server: Client ~p terminated with reason ~p~n", [Pid, Reason]),
            loop();
        stop -> ok
    end.