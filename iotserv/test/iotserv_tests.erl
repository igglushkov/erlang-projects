-module(iotserv_tests).
-include("iot_device.hrl").
-include_lib("eunit/include/eunit.hrl").

init_device(Id, Name, Address, Tempature, Indicators) ->
    #iot_device{id = Id, name = Name, address = Address,
                    tempature = Tempature, indicators = Indicators}.

add_lookup_delete_device_test() ->
    iotserv:start_link(),
    Id = 1,
    iotserv:add(Id, test_name, home, 28, [{water_consumption, 30}]),
    Expected = init_device(1, test_name , home, 28, [{water_consumption, 30}]),

    ?assertMatch({ok, Expected}, iotserv:lookup(1)),

    iotserv:delete(Id),

    ?assertMatch({error, instance}, iotserv:lookup(Id)).

change_device_test() ->
    Id = 1,
    iotserv:add(Id, test_name, home, 28, [{water_consumption, 30}]),

    Expected = init_device(Id, test_name , home, 28, [{water_consumption, 30}]),
    ?assertMatch({ok, Expected}, iotserv:lookup(Id)),

    NewIndicators = [{water_consumption, 45}],
    iotserv:change(Id, indicators, NewIndicators),
    NewExpected = Expected#iot_device{indicators =  NewIndicators},
    
    ?assertMatch({ok, NewExpected}, iotserv:lookup(Id)),

    iotserv:delete(Id),
    iotserv:stop().