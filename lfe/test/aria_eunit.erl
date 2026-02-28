%% SPDX-License-Identifier: MIT
%% EUnit tests for LFE modules.

-module(aria_eunit).
-include_lib("eunit/include/eunit.hrl").

state_new_returns_map_test() ->
    S = aria_planner:state_new(),
    ?assert(is_map(S)).

c_noop_preserves_state_test() ->
    S = aria_planner:state_new(),
    {ok, State} = aria_planner:command_dispatch(S, "c_noop", []),
    ?assert(is_map(State)),
    ?assertEqual(S, State).

dispatch_returns_ok_or_error_test() ->
    S = aria_planner:state_new(),
    Res = aria_planner:command_dispatch(S, "c_noop", []),
    ?assert((element(1, Res) =:= ok) or (element(1, Res) =:= error)).

register_and_dispatch_interactivity_test() ->
    aria_planner:command_register("c_activate_graph", {aria_domains_interactivity, c_activate_graph, 2}),
    aria_planner:command_register("c_math_add", {aria_domains_interactivity, c_math_add, 5}),
    S0 = aria_planner:state_new(),
    {ok, S1} = aria_planner:command_dispatch(S0, "c_activate_graph", ["graph1"]),
    S2 = aria_domains_interactivity:socket_value_set(
           aria_domains_interactivity:socket_value_set(S1, "node1", "a", 5.0), "node1", "b", 3.0),
    {ok, S3} = aria_planner:command_dispatch(S2, "c_math_add", ["node1", "a", "b", "value"]),
    ?assertEqual(8.0, aria_domains_interactivity:socket_value_get(S3, "node1", "value")),
    ?assert(aria_domains_interactivity:node_executed_get(S3, "node1")).

%% HDDL round-trip (Phase 1 emits only string values)
hddl_round_trip_test() ->
    S0 = aria_domains_interactivity:socket_value_set(aria_planner:state_new(), "n1", "a", "5.0"),
    S1 = aria_hddl:round_trip_state(S0),
    ?assertEqual("5.0", maps:get({socket_value, "n1", "a"}, S1)).

%% glTF load/save
gltf_load_returns_state_with_json_test() ->
    State = aria_gltf_json:load_json(<<"{}">>),
    ?assert(is_map(State)),
    ?assert(maps:is_key(json, State)).

gltf_save_returns_binary_test() ->
    State = aria_gltf_state:state_new(),
    Bin = aria_gltf_json:save_json(State),
    ?assert(is_binary(Bin)).
