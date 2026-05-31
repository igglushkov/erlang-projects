-module(config_reader).
-export([read_config/1]).

read_config(FileName) ->
    case file:read_file(FileName) of
        {ok, Binary} ->
            try jsx:decode(Binary, [return_maps]) of
                ConfigJson ->
                    #{<<"database">> := DbConf} = ConfigJson,
                    binary_to_list(db_conf_path(DbConf))
            catch
                _:Error ->
                    io:format("JSON parse error: ~p~n", [Error]),
                    {error, invalid_json}
            end;
        {error, Reason} ->
            io:format("Error on file read: ~p~n", [Reason]),
            {error, file_read_error}
    end.

db_conf_path(#{<<"path">> := Path}) -> Path.
