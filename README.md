# JsonConfix

JsonConfix provides a [Distillery](https://github.com/bitwalker/distillery) release config provider that replaces config tuples (e.g {:json, value}) with values read from a JSON file.

Most of the code has been taken from [ConfigTuples](https://github.com/rockneurotiko/config_tuples)

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `json_confix` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:json_confix, "~> 0.2.0"}
  ]
end
```

## Usage

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

```elixir
config :json_confix,
  file_path: "/path/to/my/secrets.json"  # Defaults to /tmp/json_confix.json,
  json_keys: ["secrets", "data"]
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/json_confix](https://hexdocs.pm/json_confix).

