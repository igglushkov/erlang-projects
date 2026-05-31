-export_macros([is_device_property]).
-define(is_device_property(P), 
            P == name; P == address; P == tempature; P == indicators).

