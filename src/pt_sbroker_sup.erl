-module (pt_sbroker_sup).

%% API
-export ([start_link/2, do/2, superconfig/2]).

%% supervisor callbacks
-export ([init/1]).

-define (POOL_ID, pt_sbroker_pool).

superconfig (MinPool, MaxPool) ->
  [ { pt_sbroker_sup,
      {pt_sbroker_sup, start_link, [MinPool, MaxPool]},
      permanent,
      2000,
      supervisor,
      [pt_sbroker_sup]
    }
  ].

start_link (MinPool, MaxPool) ->
  supervisor:start_link ({local, ?MODULE}, ?MODULE, [MinPool, MaxPool]).

do (N, Data) ->
  case pt_sbroker:ask (?POOL_ID) of
      {_, _} -> {error, busy};
      {go, Ref, Pid, _} ->
          pt_sbroker_worker:do(Pid, Ref, N, Data)
  end.

init ([_MinPool, MaxPool]) ->
  { ok,
    { {rest_for_one, 10, 10},
      [ { ?POOL_ID,
          {pt_sbroker, start_link, [?POOL_ID]},
          permanent,
          5000,
          worker,
          [pt_sbroker, sbroker]
        },
        { {?POOL_ID, pt_sbroker_worker_sup},
          {pt_sbroker_worker_sup, start_link, [?POOL_ID, MaxPool]},
          permanent,
          5000,
          worker,
          [pt_sbroker_worker_sup]
        }
      ]
    }
  }.
