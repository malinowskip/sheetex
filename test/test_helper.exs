env_key = "GOOGLE_SHEETS_API_KEY"

environment = Dotenvy.source!([".env.testing", System.get_env()])

api_key = environment[env_key]

case api_key do
  value when is_binary(value) ->
    System.put_env(
      "GOOGLE_SHEETS_API_KEY",
      api_key
    )

  _ ->
    raise("Please include `GOOGLE_SHEETS_API_KEY` in `.env.testing`.")
end

ExUnit.start(max_cases: 2)
