-module(event_server).

-include("include/event_info.hrl").

-export([start/0, init/1]).
-record(state, {current_id :: integer(), 
                events_info :: orddict:orddict()}).

start() ->
    Pid = spawn(?MODULE, init, [#state{current_id = 0, events_info = orddict:new()}]),
    register(?MODULE, Pid),
    {ok, Pid}.

init(State) ->
    loop(State),
    ok.

loop(State) ->
    receive
        {subscribe, From, ClientName} -> 
            MonitorRef = erlang:monitor(process, ClientName),
            io:format("event server now monitor procces ~p under ref ~p~n", [ClientName, MonitorRef]),
            From ! ok,
            loop(State);
        {add, From, ClientName, EventName, Description, Timeout} ->
            EventInfo = #event_info{client_name = ClientName,
                                    event_name = EventName,
                                    description = Description},
            EventId = State#state.current_id,
            NewDict = orddict:store(EventId, EventInfo, State#state.events_info),
            NewState = State#state{current_id = EventId + 1,
                                    events_info = NewDict},
            EventPid = event:start_link(EventId, Timeout),
            From ! {ok, EventPid, EventId},
            loop(NewState);
        {done, Id} ->
            case orddict:find(Id, State#state.events_info) of
                {ok, #event_info{
                    client_name = ClientName,
                    event_name = EventName,
                    description = Description
                    }} ->
                    NewDict = orddict:erase(Id, State#state.events_info),
                    NewState = State#state{events_info = NewDict},
                    ClientName ! {done, EventName, Description},
                    loop(NewState);
                {error} ->
                    io:format("Got unexpected event id: ~p~n", [Id]),
                    error
            end,
            loop(State);
        {'DOWN', _Ref, process, Pid, Reason} ->
            io:format("Event Server: Client ~p terminated with reason ~p~n", [Pid, Reason]),
            loop(State);
        stop -> ok
    end.