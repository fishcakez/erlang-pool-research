-module (pt_dispcount_sup).

-behaviour (gen_server).
-export ([ init/1,
           handle_call/3,
           handle_cast/2,
           handle_info/2,
           terminate/2,
           code_change/3 ]).

-export ([ start_link/0, do/2 ]).

-record (state, {info}).

-define (POOL_ID, pt_dispcount_dispatcher).
-define (MOCHIGLOBAL_ID, pt_dispcount_id).

start_link () ->
  gen_server:start_link ({local, ?MODULE}, ?MODULE, [], []).

do (N, Data) ->
  PoolId = pool_id (),
  case dispcount:checkout (PoolId) of
    {ok, CheckinReference, Pid} ->
      pt_baseline_worker:do (Pid, N, Data),
      dispcount:checkin(PoolId, CheckinReference, Pid),
      {ok, {worked, N}};
    {error, busy} ->
      {error, busy }
  end.

pool_id () ->
  mochiglobal:get (?MOCHIGLOBAL_ID).

%% gen_server callbacks
init ([]) ->
  % make sure terminate is called
  process_flag (trap_exit, true),
  ok = dispcount:start_dispatch (
         ?POOL_ID,
         {pt_dispcount_dispatch, []},
         [{restart, permanent}, {shutdown, 4000},
           {maxr, 10}, {maxt, 60}, {resources, 100}]
       ),
  {ok, Info} = dispcount:dispatcher_info (?POOL_ID),
  mochiglobal:put (?MOCHIGLOBAL_ID, Info),
  { ok, #state { info = Info } }.

handle_call (Request, From, State) ->
  error_logger:warning_msg ("~p:handle_call (~p, ~p, ~p)",
                            [?MODULE, Request, From, State]),
  { reply, ok, State }.

handle_cast (Request, State) ->
  error_logger:warning_msg ("~p:handle_cast (~p, ~p)",
                            [?MODULE, Request, State]),
  { noreply, State }.

handle_info (Info, State) ->
  error_logger:warning_msg ("~p:handle_info (~p, ~p)",[?MODULE, Info, State]),
  { noreply, State }.

terminate (_Reason, _State) ->
  dispcount:stop_dispatch (?POOL_ID),
  ok.

code_change (_OldVsn, State, _Extra) ->
  {ok, State}.
