-module (rabbithole_interface_sup).
-behaviour(supervisor).

%% API
-export([start_link/1]).

%% Supervisor callbacks
-export([init/1]).

-define(SHUTDOWN_TIME, 16#ffffffff).
-define(MAX_RESTART,  10).
-define(MAX_TIME,     60).


%% Helper macro for declaring children of supervisor
-define(CHILD(I, Type), {I, {I, start_link, []}, permanent, 5000, Type, [I]}).

%% ===================================================================
%% API functions
%% ===================================================================

start_link(Args) ->
  case catch supervisor:start_link({local, ?MODULE}, ?MODULE, [Args]) of
    X ->
      erlang:display({?MODULE, start_link, X}),
      X
  end.

%% ===================================================================
%% Supervisor callbacks
%% ===================================================================

init([]) ->
  {ok, {{one_for_one, ?MAX_RESTART, ?MAX_TIME}, []}};
  
init([Mod]) ->
  Server = ?CHILD(Mod, worker),
  
  {ok, {{one_for_one, ?MAX_RESTART, ?MAX_TIME}, [Server]}}.