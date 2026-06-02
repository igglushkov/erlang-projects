-module(code_lock_tests).
-include_lib("eunit/include/eunit.hrl").

verify(N) when N > 0 ->
    code_lock:verify(),
    verify(N - 1);
verify(0) ->
    ok.

open_on_correct_code_test() ->
    code_lock:start_link([1]),

    code_lock:button(1),
    code_lock:verify(),

    ?assertEqual(open, code_lock:state()),

    code_lock:stop().

stay_locked_on_incorrect_code_test() ->
    code_lock:start_link([1]),

    code_lock:button(2),
    code_lock:verify(),

    ?assertEqual(locked, code_lock:state()),

    code_lock:stop().

suspended_after_three_incorrect_attempts_test() ->
    code_lock:start_link([1]),

    code_lock:button(2),
    verify(code_lock:max_attempts()),

    ?assertEqual(suspended, code_lock:state()),

    code_lock:stop().

can_change_code_in_open_state_if_old_code_is_correct_test() ->
    code_lock:start_link([1]),

    code_lock:button(1),
    code_lock:verify(),

    ?assertEqual(open, code_lock:state()),
    ?assertMatch({ok, _}, code_lock:change([1], [2])),
    ?assertMatch({error, _Reason}, code_lock:change([3], [2])),

    code_lock:stop().

cannot_change_code_in_locked_state_test() ->
    code_lock:start_link([1]),

    code_lock:button(2),
    code_lock:verify(),

    ?assertEqual(locked, code_lock:state()),
    ?assertMatch({error, _Reason}, code_lock:change([1], [2])),

    code_lock:stop().

cannot_change_code_in_suspended_state_test() ->
    code_lock:start_link([1]),

    code_lock:button(2),
    verify(code_lock:max_attempts()),

    ?assertEqual(suspended, code_lock:state()),
    ?assertMatch({error, _Reason}, code_lock:change([1], [2])),

    code_lock:stop().