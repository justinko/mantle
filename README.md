# Mantle

## Installation

Add this line to your application's Gemfile:

    gem 'mantle'

or install manually by:

    $ gem install mantle


## Usage (in Rails App)

Setup a Rails initializer(`config/initializers/mantle.rb`):


```Ruby
Mantle.configure do |config|
  config.message_bus_redis = Redis.new(host: ENV["MESSAGE_BUS_REDIS_URL"] || 'localhost')
  config.message_handlers = {
    'account:update' => 'MyMessageHandler',
    'order' => ['MyMessageHandler', 'MyOtherMessageHandler']
  }
end
```

The config takes a number of options, many of which have defaults:

```Ruby
Mantle.configure do |config|
  config.message_bus_redis = Redis.new(host: 'localhost') # default: localhost
  config.logger = Rails.logger # default: Logger.new(STDOUT)
  config.redis_namespace = "my-namespace" # default: no namespace
  config.message_handlers = {'deal:update' => 'MyHandler'} # default: {}
end
```

To make the installation of mantle easier, the following command will create
these files in a Rails application:

```
$ rails g mantle:install
```

If an application only pushes messages on to the queue and doesn't listen, the
following configuration is all that's needed:

```Ruby
Mantle.configure do |config|
  config.message_bus_redis = Redis.new(host: 'localhost') # default: localhost
  config.logger = Rails.logger # default: Logger.new(STDOUT)
end
```


Publish messages to consumers:

```Ruby
Mantle::Message.new("person:create").publish({ id: message['id'], data: message['data'] })
```

The first and only argument to `Mantle::Message.new` is the channel you want to publish the
message on. The `#publish` method takes the message payload (in any format you like)
and pushes the message on to the message bus pub/sub and also adds it to the
catch up queue so offline applications can process the message when they become available.

Define message handler class with `.receive` method. For example `app/models/my_message_handler.rb`

```Ruby
class MyMessageHandler
  def self.receive(channel, message)
    puts channel # => 'order'
    puts message # => { 'id' => 5, 'name' => 'Brandon' }
  end
end
```

To run the listener:

```
$ bin/mantle
```

or with configuration:

```
$ bin/mantle -c ./config/initializers/other_file.rb
```

To run the processor:

```
$ bin/sidekiq -q mantle
```

If the Sidekiq worker should also listen on another queue, add that to the
command with:

```
$ bin/sidekiq -q mantle -q default
```

It will NOT add the `default` queue to processing if there are other queues
enumerated using the `-q` option.
