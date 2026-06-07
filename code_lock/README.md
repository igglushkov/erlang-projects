Code Lock State Machine
=====

An OTP application

Build
-----

    rebar3 compile

Usage
-----

    rebar3 eunit
    rebar3 edoc
    rebar3 shell

    code_lock:button(1).
    code_lock:button(2).
    code_lock:button(3).
    code_lock:verify().

    code_lock:change([1, 2, 3], [4, 5, 6]).

    code_lock:button(4).
    code_lock:button(5).
    code_lock:button(6).
    code_lock:verify().
