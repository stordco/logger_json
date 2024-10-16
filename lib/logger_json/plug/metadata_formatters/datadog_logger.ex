if Code.ensure_loaded?(Plug) do
  defmodule LoggerJSON.Plug.MetadataFormatters.DatadogLogger do
    @moduledoc """
    This formatter builds a metadata which is natively supported by Datadog:

      * `http` - see [DataDog](https://docs.datadoghq.com/logs/processing/attributes_naming_convention/#http-requests);
      * `phoenix.controller` - Phoenix controller that processed the request;
      * `phoenix.action` - Phoenix action that processed the request;
    """

    import Jason.Helpers, only: [json_map: 1]

    @scrubbed_keys [
      "authentication",
      "authorization",
      "confirmPassword",
      "cookie",
      "passwd",
      "password",
      "secret",
      "x-cloud-signature",
      "x-authorization",
      "x-api-key"
    ]
    @scrubbed_value "*********"

    @doc false
    def build_metadata(conn, latency, client_version_header) do
      scrub_map = scrub_map(scrub_overrides())

      http_data = [
        url: request_url(conn),
        status_code: conn.status,
        method: conn.method,
        referer: LoggerJSON.PlugUtils.get_header(conn, "referer"),
        request_id: Keyword.get(Logger.metadata(), :request_id),
        request_headers: recursive_scrub(conn.req_headers, scrub_map),
        request_params: recursive_scrub(conn.params, scrub_map),
        useragent: LoggerJSON.PlugUtils.get_header(conn, "user-agent"),
        url_details:
          json_map(
            host: conn.host,
            port: conn.port,
            path: conn.request_path,
            queryString: conn.query_string,
            scheme: conn.scheme
          )
      ]

      http_data = maybe_add_response_data(http_data, conn, scrub_map)

      client_metadata(conn, client_version_header) ++
        phoenix_metadata(conn) ++
        [
          duration: native_to_nanoseconds(latency),
          http: http_data,
          network: json_map(client: json_map(ip: LoggerJSON.PlugUtils.remote_ip(conn)))
        ]
    end

    defp native_to_nanoseconds(nil), do: nil
    defp native_to_nanoseconds(native), do: System.convert_time_unit(native, :native, :nanosecond)

    defp request_url(%{request_path: "/"} = conn), do: "#{conn.scheme}://#{conn.host}/"
    defp request_url(conn), do: "#{conn.scheme}://#{Path.join(conn.host, conn.request_path)}"

    defp client_metadata(conn, client_version_header) do
      if api_version = LoggerJSON.PlugUtils.get_header(conn, client_version_header) do
        [client: json_map(api_version: api_version)]
      else
        []
      end
    end

    defp phoenix_metadata(%{private: %{phoenix_controller: controller, phoenix_action: action}} = conn) do
      [phoenix: json_map(controller: controller, action: action, route: phoenix_route(conn))]
    end

    defp phoenix_metadata(_conn), do: []

    if Code.ensure_loaded?(Phoenix.Router) do
      defp phoenix_route(%{private: %{phoenix_router: router}, method: method, request_path: path, host: host}) do
        case Phoenix.Router.route_info(router, method, path, host) do
          %{route: route} -> route
          _ -> nil
        end
      end
    end

    defp phoenix_route(_conn), do: nil

    defp scrub_overrides, do: Application.get_env(:logger_json, :scrub_overrides, %{})
    defp default_scrub_value, do: Application.get_env(:logger_json, :scrubbed_value, @scrubbed_value)
    defp response_log_on_errors?, do: Application.get_env(:logger_json, :response_log_on_errors?, true)

    defp scrub_map(overrides) do
      default_value = default_scrub_value()

      @scrubbed_keys
      |> Enum.into(%{}, fn key -> {key, default_value} end)
      |> Map.put("authorization", {__MODULE__, :extract_public_key, [default_value]})
      |> Map.merge(overrides)
    end

    @doc """
    Scrubs the private part of the authorization header while keeping the public part for additional observability possibilities.

    ## Notes:

    - Secret/App key headers are Base64 encoded and divisible by 3 and will never contain the padding (=) character.
    - This is internally referred to as the `secret_key_header`. The public part of the key is retained in the output for name recognition and less ambiguity.
    - The expected outcome would be something like "stord_sk_publickeyasdfasdf_*******", assuming "*******" is the scrub value.
    - You can use DataDog's regex to extract the public key part and turn it into a standard attribute.
    """
    def extract_public_key(value, scrub_value) when is_binary(value) do
      case Regex.named_captures(
             ~r/Bearer stord_(?<type>sk|ak)_(?<public_key>[A-Za-z0-9+\/]+)_(?<secret_key>.+)/,
             value
           ) do
        %{"public_key" => public_key, "secret_key" => _, "type" => type} ->
          "stord_#{type}_#{public_key}_#{scrub_value}"

        _ ->
          scrub_value
      end
    end

    def extract_public_key(_value, scrub_value), do: scrub_value

    defp scrubbed_value(key, actual_value, scrub_map) do
      case Map.get(scrub_map, key) do
        {mod, func, args} when is_atom(mod) and is_atom(func) and is_list(args) ->
          {:replace, apply(mod, func, [actual_value | args])}

        static_value when is_binary(static_value) ->
          {:replace, static_value}

        _ ->
          {:keep, actual_value}
      end
    end

    defp apply_scrubbing(key, value, scrub_map) do
      case scrubbed_value(key, value, scrub_map) do
        {:replace, new_value} -> new_value
        {:keep, _} -> recursive_scrub(value, scrub_map)
      end
    end

    defp recursive_scrub(%{__struct__: Plug.Conn.Unfetched}, _scrub_map), do: "%Plug.Conn.Unfetched{}"
    defp recursive_scrub(%Plug.Upload{}, _scrub_map), do: "%Plug.Upload{}"

    defp recursive_scrub([head | _tail] = data, scrub_map) when is_tuple(head),
      do: data |> Enum.map(&recursive_scrub(&1, scrub_map)) |> Map.new()

    defp recursive_scrub(data, scrub_map) when is_list(data),
      do: Enum.map(data, &recursive_scrub(&1, scrub_map))

    defp recursive_scrub(data, scrub_map) when is_map(data),
      do: Map.new(data, fn {k, v} -> {k, apply_scrubbing(k, v, scrub_map)} end)

    defp recursive_scrub({k, v}, scrub_map),
      do: {k, apply_scrubbing(k, v, scrub_map)}

    defp recursive_scrub(data, _), do: data

    defp maybe_add_response_data(http_data, conn, scrub_map) do
      if conn.status >= 400 && response_log_on_errors?() do
        content_type = get_content_type(conn)
        response_body = decode_response_body(conn.resp_body, content_type)

        http_data ++
          [
            response_headers: recursive_scrub(conn.resp_headers, scrub_map),
            response_body: recursive_scrub(response_body, scrub_map)
          ]
      else
        http_data
      end
    end

    defp get_content_type(conn) do
      conn
      |> Plug.Conn.get_resp_header("content-type")
      |> List.first()
    end

    defp decode_response_body(body, content_type) do
      if Regex.match?(~r/application\/(vnd\.api\+)?json/, String.downcase(content_type || "")) do
        case Jason.decode(body) do
          {:ok, decoded} -> decoded
          _ -> body
        end
      else
        body
      end
    end
  end
end
