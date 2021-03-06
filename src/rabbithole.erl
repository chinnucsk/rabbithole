%%% rabbithole.erl
%% @author Ari Lerner <arilerner@mac.com>
%% @copyright 06/28/10 Ari Lerner <arilerner@mac.com>
%% @doc Rabbit hole
-module (rabbithole).
-include ("rabbithole.hrl").

-behaviour(gen_server).

%% API
-export([
  submit_job/1,             % add a job
  subscribe/1, subscribe/2, % subscribe to a queue
  publish/2, publish/3,     % publish a message to a queue
  list/1,                   % list queues
  add_worker/1,             % add a worker
  start_link/1              % start it up
]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, 
    handle_info/2, terminate/2, code_change/3]).

-define(SERVER, ?MODULE).

%%====================================================================
%% API
%%====================================================================
%%--------------------------------------------------------------------
%% Function: start_link() -> {ok,Pid} | ignore | {error,Error}
%% Description: Starts the server
%%--------------------------------------------------------------------
start_link([])                  -> throw({error, no_interface_specified});
start_link(Interface)           -> gen_server:start_link({local, ?SERVER}, ?MODULE, Interface, []).

subscribe(QueueName)            -> subscribe(QueueName, []).
subscribe(QueueName, Props)     -> gen_server:call(?SERVER, {subscribe, {QueueName, Props}}).

publish(QueueName, Msg)         -> publish(QueueName, Msg, []).
publish(QueueName, Msg, Props)  -> gen_server:call(?SERVER, {publish, {QueueName, Msg, Props}}).

submit_job(Fun)                 -> gen_server:call(?SERVER, {submit_job, Fun}).
add_worker(Fun)                 -> gen_server:call(?SERVER, {add_worker, Fun}).

list(Type)                      -> gen_server:call(?SERVER, {list, Type}).

%%====================================================================
%% gen_server callbacks
%%====================================================================

%%--------------------------------------------------------------------
%% Function: init(Args) -> {ok, State} |
%%                         {ok, State, Timeout} |
%%                         ignore               |
%%                         {stop, Reason}
%% Description: Initiates the server
%%--------------------------------------------------------------------
init([_InterfaceName]) ->
  % Interface = interface_mod(InterfaceName),
  % RealInterface = case (catch rabbithole_sup:start_interface(Interface, [])) of
  %   {ok, _} = _T -> Interface;
  %   _Else -> gproc_interface
  % end,
  RealInterface = gproc_interface,
  {ok, RealInterface}.

% interface_mod(List) when is_list(List) -> list_to_atom(lists:flatten([List, "_interface"]));
% interface_mod(Mod)  when is_atom(Mod) -> list_to_atom(lists:flatten([atom_to_list(Mod), "_interface"])).

%%--------------------------------------------------------------------
%% Function: %% handle_call(Request, From, State) -> {reply, Reply, State} |
%%                                      {reply, Reply, State, Timeout} |
%%                                      {noreply, State} |
%%                                      {noreply, State, Timeout} |
%%                                      {stop, Reason, Reply, State} |
%%                                      {stop, Reason, State}
%% Description: Handling call messages
%%--------------------------------------------------------------------
handle_call({add_worker, Fun}, _From, Interface) ->
  Interface:subscribe({job, [{callback, 
    fun({msg, BinMsg}) -> 
      local132:submit_job(fun() -> Fun(erlang:binary_to_term(BinMsg)) end)
    end}]}),
  {reply, ok, Interface};
  
handle_call({submit_job, Msg}, _From, Interface) ->
  Reply = Interface:publish({job, Msg, []}),
  {reply, Reply, Interface};
  
handle_call({subscribe, Args}, _From, Interface) ->
  Reply = Interface:subscribe(Args),
  {reply, Reply, Interface};
  
handle_call({publish, Args}, _From, Interface) ->
  Reply = Interface:publish(Args),
  {reply, Reply, Interface};

handle_call({list, Type}, _From, Interface) ->
  Reply = Interface:list(Type),
  {reply, Reply, Interface};

handle_call(_Req, _From, Interface) ->
  {reply, unknown, Interface}.
  
%%--------------------------------------------------------------------
%% Function: handle_cast(Msg, State) -> {noreply, State} |
%%                                      {noreply, State, Timeout} |
%%                                      {stop, Reason, State}
%% Description: Handling cast messages
%%--------------------------------------------------------------------
handle_cast(_Msg, Interface) ->
  {noreply, Interface}.

%%--------------------------------------------------------------------
%% Function: handle_info(Info, State) -> {noreply, State} |
%%                                       {noreply, State, Timeout} |
%%                                       {stop, Reason, State}
%% Description: Handling all non call/cast messages
%%--------------------------------------------------------------------
handle_info(_Info, State) ->
  {noreply, State}.

%%--------------------------------------------------------------------
%% Function: terminate(Reason, State) -> void()
%% Description: This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any necessary
%% cleaning up. When it returns, the gen_server terminates with Reason.
%% The return value is ignored.
%%--------------------------------------------------------------------
terminate(_Reason, Interface) ->
  Interface:stop(),
  ok.

%%--------------------------------------------------------------------
%% Func: code_change(OldVsn, State, Extra) -> {ok, NewState}
%% Description: Convert process state when code is changed
%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
  {ok, State}.

%%--------------------------------------------------------------------
%%% Internal functions
%%--------------------------------------------------------------------