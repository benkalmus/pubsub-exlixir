import Config

#for importing env specific
#import_config "#{config_env()}.exs"


## pubsub
config :pubsub,
  env: config_env()   #allows us to check env at runtime

## logger
config :logger, :default_formatter,
  format: "$time [$level]$metadata $message\n"

config :logger, :console,
  level: :info

config :logger, :file,
  level: :info,
  path: "log/file.log",
  format: "$time [$level]$metadata $message\n"
