-module (pt_sbroker_worker).

-behaviour (gen_server).

%% API
-export ([ start_link/1, do/4 ]).

%% gen_server callbacks
-export ([ init/1,
           handle_call/3,
           handle_cast/2,
           handle_info/2,
           terminate/2,
           code_change/3
         ]).

-record (state, {
                 pool_id :: atom(),
                 ref :: undefined | reference(),
                 monitor :: undefined | reference()
                }).

start_link (PoolId) ->
  gen_server:start_link(?MODULE, PoolId, []).

do (Pid, Ref, N, Data) ->
  gen_server:call (Pid, {work, Ref, N, Data}).

%%====================================================================
%% gen_server callbacks
%%====================================================================
init (PoolId) ->
  gen_server:cast (self(), ask_r),
  {ok, #state {pool_id=PoolId}}.

handle_call ({work, Ref, N, Data}, From,
             #state {ref=Ref, monitor=MRef} = State) ->
  gen_server:reply (From, {ok, pt_util:work (N, Data)}),
  demonitor (MRef, [flush]),
  ask_r (State#state{ref=undefined, monitor=undefined});
handle_call (Request, From, State) ->
  error_logger:warning_msg ("~p : Unrecognized call ~p from ~p~n",
                            [?MODULE, Request, From]),
  { reply, ok, State }.

handle_cast( ask_r, State) ->
  ask_r(State);
handle_cast (Request, State) ->
  error_logger:warning_msg ("~p : Unrecognized cast ~p~n",[?MODULE, Request]),
  { noreply, State }.

handle_info ({'DOWN', MRef, _, _, _}, #state{ monitor=MRef } = State) ->
  {stop, shutdown, State};
handle_info (Request, State) ->
  error_logger:warning_msg ("~p : Unrecognized info ~p~n",[?MODULE, Request]),
  { noreply, State }.

terminate (_Reason, #state {}) ->
  ok.

code_change (_OldVsn, State, _Extra) ->
  {ok, State}.

ask_r (#state{pool_id=PoolId} = State) ->
  case pt_sbroker:ask_r (PoolId) of
    {go, Ref, Pid, _} ->
      MRef = monitor (process, Pid),
      { noreply, State#state{ref=Ref, monitor=MRef} };
    {drop, _} ->
      gen_server:cast (self(), ask_r),
      { noreply, State }
  end.
