-module(event).

-export([start_link/2, notify/3]).

start_link(Id, TimeOut) ->
    Pid = spawn_link(?MODULE, notify, [self(), Id, TimeOut]),
    {Pid, ok}.

notify(ServerPid, Id, TimeOut) ->
    timer:send_after(TimeOut, ServerPid, {done, Id}).