defmodule JsonConfix.ProviderElixirTest do
  use ExUnit.Case, async: false

  alias JsonConfix.Provider

  setup do
    Application.put_env(:config_tuples, :distillery, false)
    :ok
  end

  defmodule CustomStruct do
    defstruct [:domain]
  end

  alias __MODULE__.CustomStruct

  describe "basic tests" do
    test "do not replace data without json tuple" do
      envs = %{}

      config = [
        host: "localhost",
        environment: :json,
        system: :production,
        port: 8080,
        ssl: true,
        some_range: 1..2
      ]

      write_config(envs, fn ->
        assert_config(config, config)
      end)
    end

    test "replace basic tuple" do
      envs = %{"HOST" => "localhost"}
      config = [host: {:json, "HOST"}]
      expected_config = [host: "localhost"]

      write_config(envs, fn ->
        assert_config(config, expected_config)
      end)
    end
  end

  describe "type casts" do
    test "cast to integer" do
      envs = %{"PORT" => "8080"}
      config = [host: {:json, "PORT", type: :integer}]
      expected_config = [host: 8080]

      write_config(envs, fn ->
        assert_config(config, expected_config)
      end)
    end

    test "cast to atom" do
      envs = %{"LOG_LEVEL" => "info", "ADAPTER" => "Elixir.Some.Atom"}

      config = [
        log_level: {:json, "LOG_LEVEL", type: :atom},
        adapter: {:json, "ADAPTER", type: :atom}
      ]

      expected_config = [log_level: :info, adapter: Some.Atom]

      write_config(envs, fn ->
        assert_config(config, expected_config)
      end)
    end

    test "cast to boolean" do
      envs = %{"TRUTHY" => "true", "FALSEY" => "false", "OTHER" => "wat"}

      config = [
        truthy: {:json, "TRUTHY", type: :boolean},
        falsey: {:json, "FALSEY", type: :boolean},
        other: {:json, "OTHER", type: :boolean}
      ]

      expected_config = [truthy: true, falsey: false, other: false]

      write_config(envs, fn ->
        assert_config(config, expected_config)
      end)
    end
  end

  describe "default option" do
    test "default value is nil" do
      envs = %{}
      config = [host: {:json, "HOST"}]
      expected_config = [host: nil]

      write_config(envs, fn ->
        assert_config(config, expected_config)
      end)
    end

    test "set default value when no env" do
      envs = %{}

      config = [
        string: {:json, "STRING", default: "cool value"},
        integer: {:json, "INTEGER", type: :integer, default: 80},
        atom: {:json, "ATOM", type: :atom, default: :info},
        boolean: {:json, "BOOL", type: :boolean, default: false}
      ]

      expected_config = [string: "cool value", integer: 80, atom: :info, boolean: false]

      write_config(envs, fn ->
        assert_config(config, expected_config)
      end)
    end
  end

  describe "literal option" do
    test "when tuple contains literal use the value passed" do
      envs = %{"HOST" => "localhost"}

      config = [
        host: {:json, :literal, {:json, "HOST"}}
      ]

      expected_config = [host: {:json, "HOST"}]

      write_config(envs, fn ->
        assert_config(config, expected_config)
      end)
    end
  end

  describe "enumerable replaces" do
    test "replace values inside a map" do
      envs = %{"HOST" => "localhost"}

      config = [
        config: %{app: %{"host" => {:json, "HOST"}, "other" => "foo"}, other: "bar"}
      ]

      expected_config = [config: %{app: %{"host" => "localhost", "other" => "foo"}, other: "bar"}]

      write_config(envs, fn ->
        assert_config(config, expected_config)
      end)
    end

    test "do not replace 2-tuple inside a list" do
      envs = %{"HOST" => "localhost"}

      config = [
        system: "HOST",
        list: ["foo", 123, {:json, "HOST"}]
      ]

      expected_config = [system: "HOST", list: ["foo", 123, {:json, "HOST"}]]

      write_config(envs, fn ->
        assert_config(config, expected_config)
      end)
    end

    test "replace value inside a list if it's not a 2-tuple" do
      envs = %{"HOST" => "localhost"}

      config = [
        system: "HOST",
        list: ["foo", 123, {:json, "HOST", type: :string}]
      ]

      expected_config = [system: "HOST", list: ["foo", 123, "localhost"]]

      write_config(envs, fn ->
        assert_config(config, expected_config)
      end)
    end
  end

  describe "required option" do
    test "raise an error when a variable is required but is not setted" do
      envs = %{}

      config = [
        my_app: [
          var: {:json, "PORT", type: :integer, required: true}
        ]
      ]

      message = "environment variable 'PORT' required but is not setted"

      write_config(envs, fn ->
        assert_raise(JsonConfix.Error, message, fn ->
          Provider.load(config, :ok)
        end)
      end)
    end

    test "do not raise when a variable is required and is setted" do
      envs = %{"PORT" => "4321"}

      config = [
        var: {:json, "PORT", type: :integer, required: true}
      ]

      expected_config = [var: 4321]

      write_config(envs, fn ->
        assert_config(config, expected_config)
      end)
    end
  end

  def transform(x) do
    {x, "transformed"}
  end

  describe "transform option" do
    test "call the transform method with the correct value" do
      envs = %{"HOST" => "localhost", "PORT" => "8080"}

      config = [
        host: {:json, "HOST", transform: {__MODULE__, :transform}},
        port: {:json, "PORT", type: :integer, transform: {__MODULE__, :transform}}
      ]

      expected_config = [host: {"localhost", "transformed"}, port: {8080, "transformed"}]

      write_config(envs, fn ->
        assert_config(config, expected_config)
      end)
    end
  end

  describe "ignore structs" do
    test "ignore regex structs" do
      envs = %{"HOST" => "localhost"}

      config = [
        host: {:json, "HOST"},
        regex: ~r/.+/
      ]

      expected_config = [
        host: "localhost",
        regex: ~r/.+/
      ]

      write_config(envs, fn ->
        assert_config(config, expected_config)
      end)
    end

    test "does not ignore other structs" do
      envs = %{"HOST" => "localhost"}

      config = [
        my_struct: %CustomStruct{domain: {:json, "HOST"}}
      ]

      expected_config = [
        my_struct: %CustomStruct{domain: "localhost"}
      ]

      write_config(envs, fn ->
        assert_config(config, expected_config)
      end)
    end
  end

  defp assert_config(config, expected) do
    config = [my_app: config]
    expected = [my_app: expected]

    compare_config(expected, Provider.load(config, :ok))
  end

  defp compare_config(config, other_config) do
    config = config |> Keyword.to_list() |> Enum.sort()
    other_config = other_config |> Keyword.to_list() |> Enum.sort()

    assert config == other_config
  end


  defp write_config(envs, callback) do
    data = Jason.encode!(%{secrets: %{data: envs}})

    File.write!("/tmp/my-secrets.json", data)

    try do
      callback.()
    after
      clean_env()
    end
  end

  defp clean_env() do
    File.rm("/tmp/my-secrets.json")
  end
end
