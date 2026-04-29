-module(client).

-export([start/1, init/0, subscribe/2]).

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

init() ->
    loop(),
    ok.

loop() ->
    receive
        Msg -> 
            Msg,
            loop()
    end.