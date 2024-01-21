%%%-------------------------------------------------------------------
%% @doc Neopixel array public API
%% @end
%%%-------------------------------------------------------------------

-module(c3card_neopixel).

-include_lib("kernel/include/logger.hrl").

-behaviour(gen_server).

-export([clear_all/0,
	 toggle_led/1, toggle_led/2,
	 start_link/1]).

-export([init/1,
	 handle_call/3,
	 handle_cast/2,
	 handle_info/2]).

-define(SERVER, ?MODULE).

-define(NEOPIXEL_SATURATION, 100).
-define(NEOPIXEL_VALUE, 15).


-type neopixel_options() :: [].

-type led() :: 0..3.

-export_type([neopixel_options/0, led/0]).

%% API

%% @doc Clear all available LEDs
-spec clear_all() -> ok | {error, Reason :: term()}.
clear_all() ->
    gen_server:call(?SERVER, clear_all).

-spec toggle_led(Led :: led()) -> ok | {error, Reason :: term()}.
toggle_led(Led) ->
    toggle_led(Led, 0).

-spec toggle_led(Led :: led(), Hue :: 0..255) -> ok | {error, Reason :: term()}.
toggle_led(Led, _Hue) when Led >= 3, Led < 0 ->
    {error, {invalid_led, Led}};
toggle_led(Led, Hue) ->
    gen_server:call(?SERVER, {toggle_led, Led, Hue}).

-spec start_link(Config :: neopixel_options()) -> gen_server:start_ret().
start_link(Config) ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, Config, []).

%% gen_server callbacks

init(Config) ->
    ?LOG_NOTICE("starting neopixels"),
    NeoPixelPin = proplists:get_value(pin, Config),
    NeoPixelTotal = proplists:get_value(total_pixels, Config),
    {ok, NeoPixel} = neopixel:start(NeoPixelPin, NeoPixelTotal),
    ok = neopixel:clear(NeoPixel),
    {ok, #{neopixel => NeoPixel}}.

%% @private
handle_call(clear_all, _From, #{neopixel := NeoPixel} = State) ->
    {reply, neopixel:clear(NeoPixel), State};
handle_call({toggle_led, Led, Hue}, _From, #{neopixel := NeoPixel} = State) ->
    ok = neopixel:set_pixel_hsv(
	   NeoPixel, Led, Hue,
	   ?NEOPIXEL_SATURATION, ?NEOPIXEL_VALUE
	  ),
    {reply, neopixel:refresh(NeoPixel), State};
handle_call(_Msg, _From, State) ->
    {reply, ok, State}.

%% @private
handle_cast(_Msg, State) ->
    {noreply, State}.

%% @private
handle_info(_Msg, State) ->
    {noreply, State}.
