# The use of Plug.Builder in another nested module is causing this check to fail.
# credo:disable-for-this-file Credo.Check.Consistency.MultiAliasImportRequireUse
defmodule LoggerJSON.Plug.MetadataFormatters.DatadogLoggerTest do
  use Logger.Case, async: false
  use Plug.Test

  import ExUnit.CaptureIO

  require Logger

  defmodule MyPlug do
    use Plug.Builder

    plug(Plug.Parsers, parsers: [:urlencoded, :json], json_decoder: Jason)
    plug(LoggerJSON.Plug, metadata_formatter: LoggerJSON.Plug.MetadataFormatters.DatadogLogger)

    plug(:return)

    defp return(conn, _opts) do
      send_resp(conn, 200, "Hello world")
    end
  end

  describe "default behavior" do
    setup do
      :ok =
        Logger.configure_backend(
          LoggerJSON,
          device: :standard_error,
          level: nil,
          metadata: :all,
          json_encoder: Jason,
          on_init: :disabled,
          formatter: LoggerJSON.Formatters.DatadogLogger,
          formatter_state: %{}
        )
    end

    test "logs request headers" do
      conn =
        :post
        |> conn("/hello/world", [])
        |> put_req_header("user-agent", "chrome")
        |> put_req_header("referer", "http://google.com")
        |> put_req_header("x-forwarded-for", "127.0.0.10")
        |> put_req_header("x-api-version", "2017-01-01")

      log =
        capture_io(:standard_error, fn ->
          MyPlug.call(conn, [])
          Logger.flush()
          Process.sleep(10)
        end)

      assert %{
               "http" => %{
                 "request_headers" => %{
                   "referer" => "http://google.com",
                   "user-agent" => "chrome",
                   "x-api-version" => "2017-01-01",
                   "x-forwarded-for" => "127.0.0.10"
                 }
               }
             } = Jason.decode!(log)
    end

    test "scrubs sensitive request headers" do
      conn =
        :post
        |> conn("/hello/world", [])
        |> put_req_header("authorization", "Bearer TESTING")
        |> put_req_header("cookie", "iwannacookie")
        |> put_req_header("x-cloud-signature", "pleasedontleakmebro")

      log =
        capture_io(:standard_error, fn ->
          MyPlug.call(conn, [])
          Logger.flush()
          Process.sleep(10)
        end)

      assert %{
               "http" => %{
                 "request_headers" => %{
                   "authorization" => "*********",
                   "cookie" => "*********",
                   "x-cloud-signature" => "*********"
                 }
               }
             } = Jason.decode!(log)
    end

    test "logs request body" do
      conn =
        :post
        |> conn("/hello/world", Jason.encode!(%{hello: :world}))
        |> put_req_header("content-type", "application/json")

      log =
        capture_io(:standard_error, fn ->
          MyPlug.call(conn, [])
          Logger.flush()
          Process.sleep(10)
        end)

      assert %{
               "http" => %{
                 "request_params" => %{
                   "hello" => "world"
                 }
               }
             } = Jason.decode!(log)
    end

    test "scrubs nested request body keys" do
      conn =
        :post
        |> conn("/hello/world", Jason.encode!(%{test: %{key: %{password: "sensitive"}}}))
        |> put_req_header("content-type", "application/json")

      log =
        capture_io(:standard_error, fn ->
          MyPlug.call(conn, [])
          Logger.flush()
          Process.sleep(10)
        end)

      assert %{
               "http" => %{
                 "request_params" => %{
                   "test" => %{
                     "key" => %{
                       "password" => "*********"
                     }
                   }
                 }
               }
             } = Jason.decode!(log)
    end
  end

  describe "specifying scrub_overrides configuration" do
    setup do
      :ok =
        Logger.configure_backend(
          LoggerJSON,
          device: :standard_error,
          level: nil,
          metadata: :all,
          json_encoder: Jason,
          on_init: :disabled,
          formatter: LoggerJSON.Formatters.DatadogLogger,
          formatter_state: %{}
        )

      override_application_env(:logger_json, :scrub_overrides, %{
        "some-unicorn-key-super-special-lul" => "$$$$",
        "use-a-callback" => fn value -> String.reverse(value) end
      })
    end

    test "scrubs with an individual value override and/or callback" do
      callback_value = "you-should-not-see-me-either"

      conn =
        :post
        |> conn("/hello/world", [])
        |> put_req_header("some-unicorn-key-super-special-lul", "you-should-not-see-me")
        |> put_req_header("use-a-callback", callback_value)
        |> put_req_header("authorization", "Bearer VERY-LEAKABLE-API-KEY")

      log =
        capture_io(:standard_error, fn ->
          MyPlug.call(conn, [])
          Logger.flush()
          Process.sleep(10)
        end)

      expected_callback_result = String.reverse(callback_value)

      assert %{
               "http" => %{
                 "request_headers" => %{
                   "authorization" => "*********",
                   "some-unicorn-key-super-special-lul" => "$$$$",
                   "use-a-callback" => ^expected_callback_result
                 }
               }
             } = Jason.decode!(log)
    end

    test "merges the default scrub behavior in with the overrides" do
      callback_value = "party-time"

      conn =
        :post
        |> conn("/hello/world", [])
        |> put_req_header("some-unicorn-key-super-special-lul", "you-should-not-see-me")
        |> put_req_header("use-a-callback", "party-time")

      log =
        capture_io(:standard_error, fn ->
          MyPlug.call(conn, [])
          Logger.flush()
          Process.sleep(10)
        end)

      expected_callback_result = String.reverse(callback_value)

      assert %{
               "http" => %{
                 "request_headers" => %{
                   "some-unicorn-key-super-special-lul" => "$$$$",
                   "use-a-callback" => ^expected_callback_result
                 }
               }
             } = Jason.decode!(log)
    end
  end

  defp override_application_env(app, key, value) do
    previous_value = Application.get_env(app, key)
    Application.put_env(app, key, value)

    on_exit(fn ->
      if previous_value do
        Application.put_env(app, key, previous_value)
      else
        Application.delete_env(app, key)
      end
    end)
  end
end
