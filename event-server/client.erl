-module(client).

-export([start/0, init/0]).

start() ->
    Pid = spawn(?MODULE, init, []),
    {ok, Pid}.

init() ->
    loop(),
    ok.

loop() ->
    receive
        Msg -> 
            Msg,
            loop()
    end.