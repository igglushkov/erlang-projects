-module(code_lock).
-behaviour(gen_statem).
-define(NAME, code_lock).

-export([start_link/1]).
-export([button/1, verify/0, clear/0, change/2]).
-export([show/0]).
-export([open/3, locked/3, suspended/3]).
-export([init/1, callback_mode/0, terminate/3]).

-define(MAX_ATTEMPTS, 3).
-define(IS_VALID_CODE(Code), is_list(Code), length(Code) > 0).

start_link(Code) when ?IS_VALID_CODE(Code) ->
    gen_statem:start_link({local, ?NAME}, ?MODULE, Code, []);

start_link(_Code) ->
    io:format("Incorrect code format or length~n").

button(Button) ->
    gen_statem:cast(?NAME, {button, Button}).

change(OldCode, NewCode) when ?IS_VALID_CODE(OldCode), ?IS_VALID_CODE(NewCode) ->
    gen_statem:call(?NAME, {change, OldCode, NewCode});

change(_OldCode, _NewCode) ->
    io:format("Invalid code format or length~n").

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

locked({call, From}, {change, _, _}, _Data) ->
    {keep_state_and_data, [{reply, From, operation_is_forbidden}]};

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

open({call, From}, {change, OldCode, NewCode}, #{code := Code} = Data) ->
    if OldCode =:= Code ->
        {keep_state, Data#{code => NewCode, length => length(NewCode)}, [{reply, From, code_changed}]};
    true ->
        {keep_state, Data, [{reply, From, incorrect_old_code}]}
    end;

open(state_timeout, lock, Data) ->
    {next_state, locked, Data}.

suspended(enter, locked, _Data) ->
    do_suspend(),
    keep_state_and_data;

suspended(cast, _EventData, _Data) ->
    io:format("In suspeneded mode~n"),
    keep_state_and_data;

suspended({call, From}, {change, _, _}, _Data) ->
    {keep_state_and_data, [{reply, From, operation_is_forbidden}]};

suspended(state_timeout, lock, Data) ->
    {next_state, locked, Data#{buttons => [], attempts => 0}}.

do_suspend() ->
    io:format("Suspended~n").

do_unlock() ->
    io:format("Unlocked~n").

do_lock() ->
    io:format("Locked~n").