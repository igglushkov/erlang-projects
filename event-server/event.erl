-module(event).

-export([start_link/2, wait/3]).

start_link(Id, TimeOut) ->
    Pid = spawn_link(?MODULE, wait, [self(), Id, TimeOut]),
    {Pid, ok}.

wait(ServerPid, Id, TimeOut) ->
    receive
        cancel -> ok
    after TimeOut ->
        ServerPid ! {done, Id}
    end.
    