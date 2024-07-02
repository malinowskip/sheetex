# Sheetex

For when you just want to fetch some rows from a Google Sheet in Elixir.

See documentation: https://hexdocs.pm/sheetex.

## Installation

The package can be installed by adding `sheetex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:sheetex, "~> 0.2.0"}
  ]
end
```

## Testing

Before running `mix test`, you need to create an `.env.testing` file and add the `GOOGLE_SHEETS_API_KEY` variable.
