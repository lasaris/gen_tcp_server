%%------------------------------------------------------------------------------
%% Copyright 2012 Krzysztof Rutka
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%------------------------------------------------------------------------------

%% @author Krzysztof Rutka <krzysztof.rutka@gmail.com>
%% @copyright 2012 Krzysztof Rutka
%% @doc Supervisor for connection handlers.
%% @private
-module(gen_tcp_server_sup).

-behaviour(supervisor).

%% Internal API
-export([start_link/4]).

%% Supervisor callbacks
-export([init/1]).

-include("gen_tcp_server.hrl").

%%------------------------------------------------------------------------------
%% Internal API functions
%%------------------------------------------------------------------------------

%% @doc Start the handler supervisor.
-spec start_link(atom(), atom(), integer(), term()) -> term().
start_link(Name, HandlerModule, Port, UserOpts) ->
	supervisor:start_link(?MODULE, [Name, HandlerModule, Port, UserOpts]).

%%------------------------------------------------------------------------------
%% Supervisor callbacks
%%------------------------------------------------------------------------------

init([Name, HandlerModule, Port, UserOpts]) ->
	%% Open listening socket
	Opts = UserOpts ++ ?GEN_TCP_SERVER_OPTS, %% TODO somehow define default GEN_TCP_SERVER_OPTS, but they must be able to be overridden in the handler module
	{ok, LSocket} = gen_tcp:listen(Port, remove_opts(Opts)),
	HandlerSpec = {gen_tcp_server_handler, {gen_tcp_server_handler, start_link, [LSocket, Name, HandlerModule]}, temporary, infinity, worker, [gen_tcp_server_handler]},
	{ok, {{simple_one_for_one, 0, 1}, [HandlerSpec]}}.

%%------------------------------------------------------------------------------
%% Helper functions
%%------------------------------------------------------------------------------

%% @doc Remove custom opts.
remove_opts(Opts) ->
	remove_opts(Opts, Opts).

remove_opts([], Opts) ->
	Opts;
remove_opts([{pool, _} | Rest], _Opts) ->
	remove_opts(Rest, Rest);
remove_opts([_ | Rest], Opts) ->
	remove_opts(Rest, Opts).