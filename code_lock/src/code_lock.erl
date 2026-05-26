-module(code_lock).
-behaviour(gen_statem).
-define(NAME, code_lock).

-export([start_link/1]).
-export([button/1]).
-export([open/3, locked/3]).
-export([init/1, callback_mode/0, terminate/3]).

start_link(Code) ->
    gen_statem:start_link({local, ?NAME}, ?MODULE, Code, []).

button(Button) ->
    gen_statem:cast(?NAME, {button, Button}).

init(Code) ->
    Data = #{code => Code, length => length(Code), buttons => []},
    {ok, locked, Data}.

callback_mode() ->
    [state_functions, state_enter].

terminate(_Reason, State, _Data) ->
    State =/= locked andalso do_lock(),
    ok.

locked(enter, _OldState, _Data) ->
    do_lock(),
    keep_state_and_data;

locked(state_timeout, _OldState, _Data) ->
    do_lock(),
    keep_state_and_data;

locked(cast, {button, Button}, 
    #{code := Code, buttons := Buttons} = Data) ->
    NewButtons = Buttons ++ [Button],
    if NewButtons == Code ->
        {next_state, open, Data#{buttons => []},
        [{state_timeout, 10_000, lock}]};
    true ->
        {keep_state, Data#{buttons => NewButtons}}
    end.

open(enter, locked, _Data) ->
    do_unlock(),
    keep_state_and_data;

open(cast, {button, _}, _Data) ->
    keep_state_and_data;

open(state_timeout, lock, Data) ->
    {next_state, locked, Data}.

do_unlock() ->
    io:format("Unlocked~n").

do_lock() ->
    io:format("Locked~n").