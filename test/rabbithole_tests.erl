-module (rabbithole_tests).
-include_lib("eunit/include/eunit.hrl").

setup() ->
  % application:start(sasl),
  test_server:start(),
  ok.
  
teardown(_X) ->
  test_server:stop(),
  ok.

starting_test_() ->
  {spawn,
    {setup,
      fun setup/0,
      fun teardown/1,
      [
        fun gproc_basic_tests/0
        % fun rabbitmq_basic_tests/0
      ]
    }
  }.

% rabbitmq_basic_tests() ->
%   try
%     rabbithole_app:start([], [rabbitmq]),
%     Queue = "a.b.c",
%     ?assert(ok =:= rabbithole:subscribe(Queue, [{callback, fun callback/1}])),
%     rabbithole:publish(Queue, erlang:term_to_binary({add, 1})),
%     timer:sleep(10),
%     ?assert(1 == test_server:get_value()),
%     rabbithole:publish(Queue, erlang:term_to_binary({add, 10})),
%     rabbithole:publish(Queue, erlang:term_to_binary({subtract, 10})),
%     timer:sleep(10),
%     ?assert(11 == test_server:get_value()),
%     rabbithole_app:stop([]),
%     passed
%   catch
%     throw:Error ->
%       Error
%   end.

callback({subscribed, _}) -> ok;
callback({msg, Msg}) ->
  message_callback(binary_to_term(Msg)).

message_callback({add, Int}) -> test_server:add(Int);
message_callback(_Else) -> ok.

tee(Msg) ->
  erlang:display({tee, Msg}).

gproc_basic_tests() ->
  rabbithole_app:start([], [gproc]),
  Queue2 = "pete",
  ?assert(true =:= rabbithole:subscribe(Queue2, [{callback, fun tee/1}])),
  Queue = "a.b.c",
  ?assert(true =:= rabbithole:subscribe(Queue, [{callback, fun callback/1}])),
  rabbithole:publish(Queue, {add, 1}),
  timer:sleep(10),
  ?assert(1 == test_server:get_value()),
  rabbithole:publish(Queue, {add, 10}),
  timer:sleep(10),
  ?assert(11 == test_server:get_value()),
  ?assert(['a.b.c', pete] == rabbithole:list(queues)),
  rabbithole_app:stop([]),
  passed.