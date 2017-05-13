%%%-------------------------------------------------------------------
%% @doc mrc public API
%% @end
%%%-------------------------------------------------------------------

-module(mrc).


%% Application callbacks
%-export([start/2, stop/1]).
-compile(export_all).


%%====================================================================
%% API
%%====================================================================
% {ok, Pid} = riakc_pb_socket:start_link("127.0.0.1", 8087).
% riakc_pb_socket:list_keys(Pid, <<"red">>).

init() ->
	init_bucket().
	%red().

red() ->
   Time1 = mrc:time(),
	{ok, Pid} = riakc_pb_socket:start_link("127.0.0.1", 8087),
	io:format("waiting for mapreduce... ~n"),
	{ok, [{_N1, R1}]} = riakc_pb_socket:mapred(
        Pid, bucket(),
        [{map, {modfun, go, map_fun_demo},undefined, true}], 10000000),
	io:format("insert result...~n"),
	lists:foreach(fun(P) -> 
    	case P of
			{_, Code, R} ->
				%{{Time, CP, Yid}, List, CList}

				riakc_pb_socket:put(Pid, 
											riakc_obj:new(bucket_red(), 
												Code, term_to_binary(R))),
				io:format("ok: ~p~n~n", [Code]);
			_ ->
				
				io:format("error =====: ~n~n")
		end
	end, R1),
	%init_red(Pid, R1),
	Time2 = mrc:time(),
	Gap = Time2 - Time1,
	io:format("~p~n", [Gap]),
	ok.
	%10 - 112
	%3000 - 120
	%Reduce.

%init_red(Pid, Red) ->
%	lists:for

bucket_red() -> 
	<<"red">>.

%%--------------------------------------------------------------------
init_bucket() ->
	{ok, Pid} = riakc_pb_socket:start_link("127.0.0.1", 8087),
	Sql = "select code from m_gp_list",
	Rows = mysql:get_assoc(Sql),
	lists:foreach(fun(Row) ->
		{_, Code} = lists:keyfind(<<"code">>, 1, Row),
		io:format("init timeseries: ~p~n", [Code]),
		TimeSeries = init_timeseries(Code),
    	riakc_pb_socket:put(Pid, riakc_obj:new(bucket(), Code, term_to_binary(TimeSeries))),
		ok
	end, Rows),
	
	% Sql1 = "select * from gp_history limit 3",
	ok.
	
%%--------------------------------------------------------------------
bucket() ->
	<<"timeseries">>.

%%--------------------------------------------------------------------
init_timeseries(Code) ->
	Sql = "select time, closePrice from gp_history where code='"++to_str(Code)++"'",
	Rows = mysql:get_assoc(Sql),
	lists:foldl(fun(Row, Reply) -> 
					{_, Time} = lists:keyfind(<<"time">>, 1, Row),
					{_, ClosePrice} = lists:keyfind(<<"closePrice">>, 1, Row),
						[{Time, ClosePrice}|Reply]
					  end, [], Rows).


%%====================================================================
%% Internal functions
%%====================================================================

to_str(X) when is_list(X) -> X;
to_str(X) when is_atom(X) -> atom_to_list(X);
to_str(X) when is_binary(X) -> binary_to_list(X);
to_str(X) when is_integer(X) -> integer_to_list(X);
to_str(X) when is_float(X) -> float_to_list(X).

time() ->
	DateTime = calendar:local_time(),
	datetime_to_timestamp(DateTime).

% 时间转时间戳，格式：{{2013,11,13}, {18,0,0}}
datetime_to_timestamp(DateTime) ->
	calendar:datetime_to_gregorian_seconds(DateTime) -  calendar:datetime_to_gregorian_seconds({{1970,1,1},{0,0,0}}) - 8 * 60 * 60.




