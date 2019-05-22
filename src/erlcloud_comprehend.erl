-module(erlcloud_comprehend).

-include("erlcloud_aws.hrl").

-type error_reason() :: term().
-type error_res() :: {error, error_reason()}.

%% Comprehend API Functions
-export([
    detect_dominant_language/2
]).

-spec detect_dominant_language(Text::binary(), Config::aws_config()) ->
    {ok, map()} | error_res().
detect_dominant_language(Text, Config) ->
    Request = #{
        <<"Text">> => Text
    },
    request(Config, "DetectDominantLanguage", Request).

request(Config0, OperationName, Request) ->
    case erlcloud_aws:update_config(Config0) of
        {ok, Config} ->
            Body       = jsx:encode(Request),
            Operation  = "Comprehend_20171127." ++ OperationName,
            Headers    = get_headers(Config, Operation, Body),
            AwsRequest = #aws_request{service         = config,
                uri             = get_url(Config),
                method          = post,
                request_headers = Headers,
                request_body    = Body},
            request(Config, AwsRequest);
        {error, Reason} ->
            {error, Reason}
    end.

request(Config, Request) ->
    Result = erlcloud_retry:request(Config, Request, fun handle_result/1),
    case erlcloud_aws:request_to_return(Result) of
        {ok, {_, <<>>}}     -> {ok, #{}};
        {ok, {_, RespBody}} -> {ok, jsx:decode(RespBody, [return_maps])};
        {error, _} = Error  -> Error
    end.

handle_result(#aws_request{response_type = ok} = Request) ->
    Request;
handle_result(#aws_request{response_type    = error,
    error_type      = aws,
    response_status = Status} = Request)
    when Status >= 500 ->
    Request#aws_request{should_retry = true};
handle_result(#aws_request{response_type = error,
    error_type    = aws} = Request) ->
    Request#aws_request{should_retry = false}.

get_headers(#aws_config{comprehend_host = Host} = Config, Operation, Body) ->
    Headers = [{"host",         Host},
        {"x-amz-target", Operation},
        {"content-type", "application/x-amz-json-1.1"}],
    Region = erlcloud_aws:aws_region_from_host(Host),
    erlcloud_aws:sign_v4_headers(Config, Headers, Body, Region, "comprehend").

get_url(#aws_config{comprehend_scheme = Scheme,
    comprehend_host   = Host,
    comprehend_port   = Port}) ->
    Scheme ++ Host ++ ":" ++ integer_to_list(Port).
