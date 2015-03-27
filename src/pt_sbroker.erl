-module (pt_sbroker).

%% API
-export ([start_link/1, ask/1, ask_r/1]).

%% sbroker callbacks
-export ([init/1]).

start_link (PoolId) ->
  sbroker:start_link ({local, PoolId}, ?MODULE, []).

ask (PoolId) ->
  sbroker:ask (PoolId).

ask_r (PoolId) ->
  sbroker:ask_r (PoolId).

init ([]) ->
  AskSpec = {squeue_codel_timeout, {0, 5, 6}, out, infinity, drop},
  AskRSpec = {squeue_naive, undefined, out_r, infinity, drop},
  Interval = 200,
  { ok,
    {AskSpec, AskRSpec, Interval}
  }.
