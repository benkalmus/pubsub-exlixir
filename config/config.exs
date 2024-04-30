import Config

#for importing env specific
#import_config "#{config_env()}.exs"


## pubsub
config :pubsub,
  #allows us to check env at runtime
  env: config_env()

## logger
config :logger, :default_formatter,
  format: "\n$time [$level]$metadata $message\n",
  metadata: [:module, :line]

#Configure (deprecated console logger, see https://hexdocs.pm/logger/main/Logger.Backends.Console.html)
config :logger, :backends, [Logger.Backends.Console]

#Configure default handler (see https://hexdocs.pm/logger/Logger.html#module-boot-configuration)
config :logger, :default_handler,
  config: [
    file: ~c"log/console.log",
    filesync_repeat_interval: 5000,
    file_check: 5000,
    max_no_bytes: 10_000_000,
    max_no_files: 5,
    compress_on_rotate: true
  ]
