-module(client).

-export([start/1, init/1, subscribe/2, unsubscribe/2, add/5, cancel/3, shutdown_server/1]).

-define(TIMEOUT, 2000).

-record(state, {monitor_refs :: [{ServerName :: atom(), MonitorRef :: reference()}]}).

start(Name) ->
    Pid = spawn(?MODULE, init, [#state{}]),
    register(Name, Pid),
    {ok, Name, Pid}.

-spec subscribe(ClientName :: atom(), ServerName :: atom()) -> {ok, reference()} | {error, atom()}.

subscribe(ClientName, ServerName) ->
    ServerName ! {subscribe, self(), ClientName},
    receive
        ok -> ok;
        {error, Reason} ->
            {error, Reason}
    after ?TIMEOUT ->
        {error, timeout}
    end.

unsubscribe(ClientName, ServerName) ->
    ServerName ! {unsubscribe , self(), ClientName},
    receive 
        ok -> ok;
        {error , Reason} ->
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

cancel(ClientName, ServerName, EventName) ->
    ServerName ! {cancel, self(), ClientName, EventName},
    receive
        ok -> ok;
        _ -> error
    after ?TIMEOUT ->
        {error, timeout}
    end.

shutdown_server(ServerName) ->
    ServerName ! {shutdown, self()},
    receive
        ok -> ok;
        _ -> error
    after ?TIMEOUT ->
        {error, timeout}
    end.

init(State) ->
    loop(State),
    ok.

loop(State) ->
    receive
        {done, EventName, Description} -> 
            io:format("Client ~p : ~p ~p is timeout~n", [self(), EventName, Description]),
            loop(State);
        {subscribe, ServerName} ->
            MonitorRef = erlang:monitor(process, ServerName),
            NewMonitorRefs = [{ServerName, MonitorRef} | State#state.monitor_refs],
            NewState = State#state{monitor_refs = NewMonitorRefs},
            io:format("client ~p now monitor procces ~p under ref ~p~n", [self(), ServerName, MonitorRef]),
            loop(NewState);
        {unsubscribe, ServerName} ->
            case proplists:lookup(ServerName, State#state.monitor_refs) of
                {ServerName, _MonitorRef} ->
                    NewMonitorRefs = proplists:delete(ServerName, State#state.monitor_refs),
                    NewState = State#state{monitor_refs = NewMonitorRefs},
                    io:format("client ~p: Unsubscribed from ~p~n", [self(), ServerName]),
                    loop(NewState);
                none ->
                    io:format("client ~p: Unknown ServerName: ~p~n", [self(), ServerName])
            end,
            loop(State);
        {canceled, EventName} ->
            io:format("~p is canceled~n", [EventName]),
            loop(State);
        {'DOWN', _Ref, process, Pid, Reason} ->
            io:format("Client: Event server ~p terminated with reason ~p~n", [Pid, Reason]),
            loop(State);
        _ -> loop(State)
    end.