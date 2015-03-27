-module (pt_sbroker_worker_sup).

%% API
-export ([start_link/2]).

%% supervisor callbacks
-export ([init/1]).

start_link (PoolId, MaxPool) ->
  supervisor:start_link ({local, ?MODULE}, ?MODULE, [PoolId, MaxPool]).

init ([PoolId, MaxPool]) ->
  Children = [worker (Id, PoolId) || Id <- lists:seq (1, MaxPool)],
  { ok,
    {{one_for_one, 10, 10}, Children}
  }.

worker (Id, PoolId) ->
  { {pt_sbroker_worker, Id},
    {pt_sbroker_worker, start_link, [PoolId]},
    permanent,
    2000,
    worker,
    [pt_sbroker_worker]
  }.
