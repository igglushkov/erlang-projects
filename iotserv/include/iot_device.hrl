-export_macros([is_device_property]).
-export_type([id/0, name/0, address/0, tempature/0, indicators/0, dev_property/0]).

-type id() :: pos_integer().
-type name() :: term().
-type address() :: term().
-type tempature() :: number().
-type indicators() :: [{term(), term()}].

-type dev_property() :: name | address | tempature | indicators.

-define(is_device_property(P),
    P == name; P == address; P == tempature; P == indicators
).

%% @doc iot_device definition

-record(iot_device, {
    id :: id(),
    name :: name(),
    address :: address(),
    tempature :: tempature(),
    indicators :: indicators()
}).
