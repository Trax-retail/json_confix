defmodule JsonConfix.Provider do
  @moduledoc """
  This module provides an implementation of Distilery's configuration provider
  behavior that changes runtime config tuples for the value.

  ## Usage
  Add the following to your `rel/config.exs`
    release :myapp do
      # ...snip...
      set config_providers: [
        JsonConfix.Provider
      ]
    end

  If your JSON file with the configuration is like this

  ```
  // /path/to/my/secrets.json

  {
    "noise": {
      ...
    },
    "secrets": {
      "data": {
        "MY_SECRET": "***************",
        "ANOTHER_SECRET": "**************"
      }
    },
    "more_noise": {
      ...
    }
  }
  ```

  Your configuration should look like:

  ```
  config :json_confix,
    file_path: "/path/to/my/secrets.json"  # Defaults to /tmp/json_confix.json,
    json_keys: ["secrets", "data"]
  ```

  This will result in `JsonConfix.Provider` being invoked during boot, at which point it
  will evaluate the current configuration for all the apps and replace the config tuples when needed, persisting it in the configuration.

  ## Configuration tuples
  The json config tuple always start with `:json`, and can have some options as keyword, the syntax are like this:
  - `{:json, env_name}`
  - `{:json, env_name, opts}`

  The available options are:
  - `type`: Type to cast the value, one of `:string`, `:integer`, `:atom`, `:boolean`. Default to `:string`
  - `default`: Default value if the key is not persent in the JSON file. Default no `nil`
  - `transform`: Function to transform the final value, the syntax is {Module, :function}
  - `required`: Set to true if this key is not persent in the JSON file, if not setted it will raise an error. Default no `false`

  For example:
  - `{:json, "MYSQL_PORT", type: :integer, default: 3306}`
  - `{:json, "ENABLE_LOG", type: :boolean, default: false}`
  - `{:json, "HOST", transform: {MyApp.UrlParser, :parse}}`

  If you need to store the literal values `{:json, term()}`, `{:json, term(), Keyword.t()}`,
  you can use `{:json, :literal, term()}` to disable JsonConfix config interpolation. For example:
  - `{:json, :literal, {:json, "HOST}}`
  """

  use Distillery.Releases.Config.Provider

  @impl Provider
  def init(_cfg) do
    # Build up configuration and persist
    for {app, _, _} <- Application.loaded_applications() do
      load_env(app)
    end
  end

  defp load_env(app) do
    base = Application.get_all_env(app)

    new_config = replace(base)

    merged = deep_merge(base, new_config)

    persist(app, merged)
  end

  defp persist(_app, []), do: :ok

  defp persist(app, [{k, v} | rest]) do
    Application.put_env(app, k, v, persistent: true)
    persist(app, rest)
  end

  def replace({:json, :literal, value}), do: value
  def replace({:json, value}), do: replace_value(value, [])
  def replace({:json, value, opts}), do: replace_value(value, opts)

  def replace(list) when is_list(list) do
    Enum.map(list, fn
      {key, value} -> {replace(key), replace(value)}
      other -> replace(other)
    end)
  end

  def replace(map) when is_map(map) do
    Map.new(map, fn
      {key, value} ->
        {replace(key), replace(value)}

      other ->
        replace(other)
    end)
  end

  def replace(tuple) when is_tuple(tuple) do
    tuple |> Tuple.to_list() |> Enum.map(&replace/1) |> List.to_tuple()
  end

  def replace(other) do
    other
  end

  defp replace_value(env, opts) do
    type = Keyword.get(opts, :type, :string)
    default = Keyword.get(opts, :default)
    required = Keyword.get(opts, :required, false)
    transformer = Keyword.get(opts, :transform)

    env
    |> get_json_value(type)
    |> env_required(required)
    |> env_unwrap_default(default)
    |> transform(transformer)
  end

  defp get_json_value(env, type) do
    with file_path <- Application.get_env(:json_confix, :file_path, "/tmp/json_confix.json"),
         {:ok, file} <- File.read(file_path),
         {:ok, json} <- Jason.decode(file),
         data <- fetch_data(json),
         {:ok, value} <- Map.fetch(data, env) do
      {:ok, cast(value, type)}
    else
      _ -> {:error, {:required, env}}
    end
  end

  defp fetch_data(json) do
    keys = Application.get_env(:json_confix, :json_keys, [])

    Enum.reduce(keys, json, fn key, data ->
      Map.fetch!(data, key)
    end)
  end

  defp env_required({:error, _} = error, true) do
    raise JsonConfix.Error, error
  end

  defp env_required(env, _other), do: env

  defp env_unwrap_default({:ok, value}, _default), do: value
  defp env_unwrap_default({:error, _}, default), do: default

  defp transform(value, nil), do: value

  defp transform(value, {module, function}) do
    apply(module, function, [value])
  end

  defp cast(nil, _type), do: nil
  defp cast(value, :string), do: value
  defp cast(value, :atom), do: String.to_atom(value)
  defp cast(value, :integer), do: String.to_integer(value)
  defp cast("true", :boolean), do: true
  defp cast("false", :boolean), do: false
  defp cast(_, :boolean), do: false

  defp deep_merge(a, b) when is_list(a) and is_list(b) do
    if Keyword.keyword?(a) and Keyword.keyword?(b) do
      Keyword.merge(a, b, &deep_merge/3)
    else
      b
    end
  end

  defp deep_merge(_k, a, b) when is_list(a) and is_list(b) do
    if Keyword.keyword?(a) and Keyword.keyword?(b) do
      Keyword.merge(a, b, &deep_merge/3)
    else
      b
    end
  end

  defp deep_merge(_k, a, b) when is_map(a) and is_map(b) do
    Map.merge(a, b, &deep_merge/3)
  end

  defp deep_merge(_k, _a, b), do: b
end
