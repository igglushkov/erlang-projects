%%%-------------------------------------------------------------------
%% @doc code_lock top level supervisor.
%% @end
%%%-------------------------------------------------------------------

-module(code_lock_sup).

-behaviour(supervisor).

-export([start_link/1]).

-export([init/1]).

-define(SERVER, ?MODULE).

start_link(Code) ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, Code).

%% sup_flags() = #{strategy => strategy(),         % optional
%%                 intensity => non_neg_integer(), % optional
%%                 period => pos_integer()}        % optional
%% child_spec() = #{id => child_id(),       % mandatory
%%                  start => mfargs(),      % mandatory
%%                  restart => restart(),   % optional
%%                  shutdown => shutdown(), % optional
%%                  type => worker(),       % optional
%%                  modules => modules()}   % optional
init(Code) ->
    SupFlags = #{
        strategy => one_for_one,
        intensity => 1,
        period => 1
    },
    CodeLockChild =
        {code_lock, {code_lock, start_link, [Code]}, transient, 2000, worker, [code_lock]},
    {ok, {SupFlags, [CodeLockChild]}}.

%% internal functions
