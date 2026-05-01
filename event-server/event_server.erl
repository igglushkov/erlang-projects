-module(event_server).

-include("include/event_info.hrl").

-export([start/0, init/1]).
-record(state, {current_id :: integer(),
                clients :: [atom()], 
                events_info :: orddict:orddict(),
                events_procs :: orddict:orrdict()}).

start() ->
    Pid = spawn(?MODULE, init, [#state{current_id = 0, 
                                        clients = [],
                                        events_info = orddict:new(),
                                        events_procs = orddict:new()}]),
    register(?MODULE, Pid),
    {ok, Pid}.

init(State) ->
    loop(State),
    ok.

loop(State) ->
    receive
        {subscribe, From, ClientName} -> 
            case lists:member(ClientName, State#state.clients) of
                true ->
                    From ! {error, already_subscribed};
                false ->
                    MonitorRef = erlang:monitor(process, ClientName),
                    NewClients = [ClientName | State#state.clients],
                    NewState = State#state{clients = NewClients},
                    io:format("event server now monitor procces ~p under ref ~p~n", [ClientName, MonitorRef]),
                    ClientName ! {subscribe, self()},
                    From ! ok,
                    loop(NewState)
            end,
            loop(State);
        {unsubscribe, From, ClientName} ->
            case lists:member(ClientName, State#state.clients) of
                true ->
                    NewClients = lists:delete(ClientName),
                    NewState = State#state{clients = NewClients},
                    %% TODO Demonitor process
                    %% TODO Remove all events added by that client
                    loop(NewState);
                false ->
                    From ! {error, unknwon_client}
            end,
            loop(State);
        {add, From, ClientName, EventName, Description, Timeout} ->
            case lists:member(ClientName, State#state.clients) of
                true ->
                    EventInfo = #event_info{client_name = ClientName,
                                    event_name = EventName,
                                    description = Description},
                    EventId = State#state.current_id,
                    {EventPid, ok} = event:start_link(EventId, Timeout),
                    NewEvInfo = orddict:store(EventId, EventInfo, State#state.events_info),
                    NewEvProcs = orddict:store(EventName, {ClientName, EventId, EventPid}, State#state.events_procs),
                    NewState = State#state{current_id = EventId + 1,
                                            events_info = NewEvInfo,
                                            events_procs = NewEvProcs},
                    From ! {ok, EventPid, EventId},
                    loop(NewState);
                false ->
                    From ! {error, unknown_client}
            end,
            loop(State);
        {cancel, From, ClientName, EventName} ->
            case orddict:find(EventName, State#state.events_procs) of
                {ok, {ClientName, Id, Pid}} -> 
                    Pid ! cancel,
                    NewEvInfo = orddict:erase(Id, State#state.events_info),
                    NewEvProcs = orddict:erase(EventName, State#state.events_procs),
                    NewState = State#state{events_info = NewEvInfo,
                                            events_procs = NewEvProcs},
                    From ! ok,
                    ClientName ! {canceled, EventName},
                    loop(NewState);
                _ -> 
                    From ! {error, unknown_event}
            end,
            loop(State);
        {done, Id} ->
            case orddict:find(Id, State#state.events_info) of
                {ok, #event_info{
                    client_name = ClientName,
                    event_name = EventName,
                    description = Description
                    }} ->
                    NewEvInfo = orddict:erase(Id, State#state.events_info),
                    NewEvProcs = orddict:erase(Id, State#state.events_procs),
                    NewState = State#state{events_info = NewEvInfo,
                                        events_procs = NewEvProcs},
                    ClientName ! {done, EventName, Description},
                    loop(NewState);
                error ->
                    io:format("Got unexpected event id: ~p~n", [Id]),
                    error
            end,
            loop(State);
        {'DOWN', _Ref, process, Pid, Reason} ->
            io:format("Event Server: Client ~p terminated with reason ~p~n", [Pid, Reason]),
            loop(State);
        {shutdown, From} -> 
            From ! ok,
            io:format("Shutting down event server~n"),
            exit(shutdown);
        _ -> 
            loop(State) 
    end.