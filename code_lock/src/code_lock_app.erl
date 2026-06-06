%%%-------------------------------------------------------------------
%% @doc code_lock public API
%% @end
%%%-------------------------------------------------------------------

-module(code_lock_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    {ok, Code} = application:get_env(code),
    code_lock_sup:start_link(Code).

stop(_State) ->
    ok.

%% internal functions
