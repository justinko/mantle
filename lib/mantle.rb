require 'rubygems'
require 'redis'
require 'sidekiq'
require 'json'

begin
  require 'pry'
rescue LoadError
end

require_relative 'mantle/local_redis'
require_relative 'mantle/message_router'
require_relative 'mantle/catch_up_handler'
require_relative 'mantle/message_bus'
require_relative 'mantle/message_handler'
require_relative 'mantle/load_workers'

module Mantle
  class << self
    attr_accessor :message_bus_channels, :message_bus_redis, :message_bus_catch_up_key_name

    # SubscribedModels = %w{person contact lead company deal note comment}
    # SubscribedActions = %w{create update delete}
    # Mantle.configure do |config|
    #   config.message_bus_channels = ['update:deal', 'create:person']
    #   config.message_bus_redis = Redis::Namespace.new(:jupiter, :redis => Redis.new)
    #   config.message_bus_catch_up_key_name = "action_list"
    # end
    #
    def configure
      yield self
      true
    end

    def run!
      MessageBus.new.monitor!
    end

    def message_handler=(handler)
      @message_handler = handler
    end

    def message_handler
      @message_handler || MessageHandler
    end

    def receive_message(action, model, message)
      $stdout << "RECEIVE MESSAGE!\n"
      message_handler.receive(action, model, message)
    end
  end

  private

  def self.setup_sidekiq
    Sidekiq.configure_client do |config|
      config.redis = { :namespace => 'mantle', :size => 1}
    end
    Sidekiq.configure_server do |config|
      config.redis = { :namespace => 'mantle' }
    end
  end

end

