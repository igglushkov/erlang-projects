-module(code_lock).
-behaviour(gen_statem).
-define(NAME, code_lock).

-export([start_link/1]).
-export([button/1, verify/0, clear/0, change/2, state/0, max_attempts/0, stop/0]).
-export([show/0]).
-export([open/3, locked/3, suspended/3]).
-export([init/1, callback_mode/0, terminate/3]).

-define(MAX_ATTEMPTS, 3).

-define(IS_DIGIT(D), is_integer(D), D >= 0, D =< 9).
-define(IS_VALID_CODE(Code), is_list(Code), Code =/= [], ?IS_DIGIT(hd(Code))).

-type code() :: [integer()].

%% @doc Starts state machine with the given code.

-spec start_link(Code :: code()) -> {ok, Pid :: pid()} | {error, _Reason}.

start_link(Code) ->
    gen_statem:start_link({local, ?NAME}, ?MODULE, Code, []).

stop() ->
    gen_statem:stop(?NAME).

max_attempts() ->
    ?MAX_ATTEMPTS.

button(Button) ->
    gen_statem:cast(?NAME, {button, Button}).

%% @doc Change code. Works if OldCode is correct and code lock is opened.

-spec change(OldCode :: code(), NewCode :: code()) -> ok.

change(OldCode, NewCode) ->
    gen_statem:call(?NAME, {change, OldCode, NewCode}).

verify() ->
    gen_statem:cast(?NAME, verify).

clear() ->
    gen_statem:cast(?NAME, clear).

show() ->
    gen_statem:call(?NAME, show).

state() ->
    gen_statem:call(?NAME, state).

init(Code) when ?IS_VALID_CODE(Code) ->
    Data = #{code => Code, attempts => 0, buttons => []},
    {ok, locked, Data};
init(Code) ->
    {stop, invalid_code_format, Code}.

callback_mode() ->
    [state_functions, state_enter].

terminate(_Reason, State, _Data) ->
    State =/= locked andalso do_lock(),
    ok.

%%
%% locked state

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
locked(
    cast,
    verify,
    #{code := Code, buttons := Buttons} = Data
) when Buttons =:= Code ->
    {next_state, open, Data#{buttons => [], attempts => 0}, [{state_timeout, 10_000, lock}]};
locked(cast, verify, #{attempts := Attempts} = Data) when Attempts + 1 == ?MAX_ATTEMPTS ->
    {next_state, suspended, Data, [{state_timeout, 10_000, lock}]};
locked(cast, verify, #{attempts := Attempts} = Data) ->
    {keep_state, Data#{attempts => Attempts + 1}};
locked({call, From}, show, #{buttons := Buttons}) ->
    {keep_state_and_data, [{reply, From, Buttons}]};
locked({call, From}, {change, _, _}, _Data) ->
    Reply = {error, operation_is_forbidden},
    {keep_state_and_data, [{reply, From, Reply}]};
locked({call, From}, state, _Data) ->
    {keep_state_and_data, [{reply, From, locked}]}.

%%
%% open state

open(enter, locked, _Data) ->
    do_unlock(),
    keep_state_and_data;
open(state_timeout, lock, Data) ->
    {next_state, locked, Data};
open(cast, {button, _}, _Data) ->
    keep_state_and_data;
open({call, From}, {change, OldCode, NewCode}, #{code := Code} = Data) when
    OldCode =:= Code, ?IS_VALID_CODE(NewCode)
->
    Reply = {ok, code_changed},
    {keep_state, Data#{code => NewCode}, [{reply, From, Reply}]};
open({call, From}, {change, _OldCode, _NewCode}, _Data) ->
    Reply = {error, incorrect_code_format},
    {keep_state_and_data, [{reply, From, Reply}]};
open({call, From}, state, _Data) ->
    {keep_state_and_data, [{reply, From, open}]}.

%%
%% suspended state

suspended(enter, locked, _Data) ->
    do_suspend(),
    keep_state_and_data;
suspended(state_timeout, lock, Data) ->
    {next_state, locked, Data#{buttons => [], attempts => 0}};
suspended(cast, _EventData, _Data) ->
    io:format("In suspeneded mode~n"),
    keep_state_and_data;
suspended({call, From}, {change, _, _}, _Data) ->
    Reply = {error, operation_is_forbidden},
    {keep_state_and_data, [{reply, From, Reply}]};
suspended({call, From}, state, _Data) ->
    {keep_state_and_data, [{reply, From, suspended}]}.

do_suspend() ->
    io:format("Suspended~n").

do_unlock() ->
    io:format("Unlocked~n").

do_lock() ->
    io:format("Locked~n").
