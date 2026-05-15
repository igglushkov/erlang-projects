
-record(iot_device, {id :: integer(), 
                name :: term(),
                address :: term(),
                tempature :: integer(),
                indicators :: [integer()]}).
