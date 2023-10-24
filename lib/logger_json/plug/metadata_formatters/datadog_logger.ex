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
      "x-authorization"
    ]
    @scrubbed_value "*********"

    @doc false
    def build_metadata(conn, latency, client_version_header) do
      scrub_map = scrub_map(scrub_overrides())

      client_metadata(conn, client_version_header) ++
        phoenix_metadata(conn) ++
        [
          duration: native_to_nanoseconds(latency),
          http:
            json_map(
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
            ),
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

    defp scrub_map(overrides) do
      default_value = default_scrub_value()

      @scrubbed_keys
      |> Enum.into(%{}, fn key -> {key, default_value} end)
      |> Map.put("authorization", {__MODULE__, :extract_public_key, [default_value]})
      |> Map.merge(overrides)
    end

    @doc """
    Extracts the public part from the authorization header and returns it as the scrubbed value for additional observability.

    ## Notes:
    - Secret key headers are Base64 encoded and divisible by 3 and will never contain the padding (=) character.
    - This is internally referred to as the `secret_key_header`, but calling it a public_key for name recognition and to be less scary.
    """
    def extract_public_key(value, default_value) do
      case Regex.named_captures(~r/Bearer stord_sk_(?<public_key>[A-Za-z0-9+\/]+)_.+/, value) do
        %{"public_key" => public_key} -> public_key
        _ -> default_value
      end
    end

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

    defp recursive_scrub([head | _tail] = data, scrub_map) when is_tuple(head),
      do: data |> Enum.map(&recursive_scrub(&1, scrub_map)) |> Map.new()

    defp recursive_scrub(data, scrub_map) when is_list(data),
      do: Enum.map(data, &recursive_scrub(&1, scrub_map))

    defp recursive_scrub(data, scrub_map) when is_map(data),
      do: Map.new(data, fn {k, v} -> {k, apply_scrubbing(k, v, scrub_map)} end)

    defp recursive_scrub({k, v}, scrub_map),
      do: {k, apply_scrubbing(k, v, scrub_map)}

    defp recursive_scrub(data, _), do: data
  end
end
