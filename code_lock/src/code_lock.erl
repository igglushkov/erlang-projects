-module(code_lock).
-behaviour(gen_statem).
-define(NAME, code_lock).

-export([start_link/1]).
-export([button/1, verify/0, clear/0]).
-export([show/0]).
-export([open/3, locked/3, suspended/3]).
-export([init/1, callback_mode/0, terminate/3]).

-define(MAX_ATTEMPTS, 3).

start_link(Code) ->
    gen_statem:start_link({local, ?NAME}, ?MODULE, Code, []).

button(Button) ->
    gen_statem:cast(?NAME, {button, Button}).

verify() ->
    gen_statem:cast(?NAME, verify).

clear() ->
    gen_statem:cast(?NAME, clear).

show() ->
    gen_statem:call(?NAME, show).

init(Code) ->
    Data = #{code => Code, length => length(Code), attempts => 0, buttons => []},
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

locked(cast, {button, Button}, #{buttons := Buttons} = Data) ->
    {keep_state, Data#{buttons => Buttons ++ [Button]}};

locked(cast, clear, Data) ->
    {keep_state, Data#{buttons => []}};

locked({call, From}, show, #{buttons := Buttons}) ->
    {keep_state_and_data, [{reply, From, Buttons}]};

locked(cast, verify, 
    #{code := Code, attempts := Attempts, buttons := Buttons} = Data) ->
    if Buttons == Code ->
        {next_state, open, Data#{buttons => [], attempts => 0},
        [{state_timeout, 10_000, lock}]};
    true ->
        if Attempts + 1 == ?MAX_ATTEMPTS ->
            {next_state, suspended, Data, [{state_timeout, 10_000, lock}]};
        true ->
            {keep_state, Data#{attempts => Attempts + 1}}
        end
    end.

open(enter, locked, _Data) ->
    do_unlock(),
    keep_state_and_data;

open(cast, {button, _}, _Data) ->
    keep_state_and_data;

open(state_timeout, lock, Data) ->
    {next_state, locked, Data}.

suspended(enter, locked, _Data) ->
    do_suspend(),
    keep_state_and_data;

suspended(cast, _EventData, _Data) ->
    io:format("In suspeneded mode~n"),
    keep_state_and_data;

suspended(state_timeout, lock, Data) ->
    {next_state, locked, Data#{buttons => [], attempts => 0}}.

do_suspend() ->
    io:format("Suspended~n").

do_unlock() ->
    io:format("Unlocked~n").

do_lock() ->
    io:format("Locked~n").