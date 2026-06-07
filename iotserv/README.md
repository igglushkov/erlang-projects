iotserv
=====

An OTP application

Build
-----

    rebar3 compile
    rebar3 eunit
    rebar3 edoc

Usage

---
    iotserv:add(1, water_bottle, home, 28, [{water_consumption, 30}]).
    iotserv:lookup(1).
    iotserv:change(1, address, work).
    iotserv:change(1, indicators, [{water_consumption, 50}]).
    iotserv:lookup(1).
    iotserv:delete(1).
