# JsonConfix

Load app configuration from a JSON file.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `json_confix` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:json_confix, "~> 0.1.1"}
  ]
end
```

## Usage

Add this to your configuration:

```elixir
config :json_confix,
  file_path: "/path/to/my/secrets.json"  # Defaults to /tmp/json_confix.json
```

The JSON file must follow the following format:

```json
{
  ...
  "data": {
    "MY_SECRET": "***************",
    ...
    "ANOTHER_SECRET": "**************"
  },
  ...
}
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/json_confix](https://hexdocs.pm/json_confix).

