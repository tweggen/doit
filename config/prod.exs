import Config

# Note we also include the path to a cache manifest
# containing the digested version of static files. This
# manifest is generated by the `mix assets.deploy` task,
# which you should run after static files are built and
# before starting your production server.
config :auth2024, Auth2024Web.Endpoint, cache_static_manifest: "priv/static/cache_manifest.json"

# Configures Swoosh API Client
config :swoosh, api_client: Swoosh.ApiClient.Finch, finch_name: Auth2024.Finch

# Disable Swoosh Local Memory Storage
config :swoosh, local: false

# Do not print debug messages in production
config :logger, level: :info

config :assent,
  github: [
    redirect_uri: "https://geoffrey.fly.dev/auth/github/callback",
  ],
  google: [
    redirect_uri: "https://geoffrey.fly.dev/auth/google/callback",
  ]
