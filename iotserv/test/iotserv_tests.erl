-module(iotserv_tests).
-include("iot_device.hrl").
-include_lib("eunit/include/eunit.hrl").

init_device(Id, Name, Address, Tempature, Indicators) ->
    #iot_device{id = Id, name = Name, address = Address,
                    tempature = Tempature, indicators = Indicators}.

add_device_test() ->
    iotserv:start_link(),
    iotserv:add(1, test_name, home, 28, [{water_consumption, 30}]),
    Expected = init_device(1, test_name , home, 28, [{water_consumption, 30}]),

    ?assertMatch({ok, Expected}, iotserv:lookup(1)),

    iotserv:stop().