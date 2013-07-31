require 'rubygems'
require 'redis'
require 'sidekiq'
require 'json'

require_relative 'mantle/local_redis'
require_relative 'mantle/message_router'
require_relative 'mantle/catch_up_handler'
require_relative 'mantle/outside_redis_listener'
require_relative 'mantle/message_handler'
require_relative 'mantle/load_workers'

module Mantle
  extend Configuration
  class << self
    attr_accessor :subscription_channels

    # Mantle.configure do |config|
    #   config.subscription_channels = ['update:deal', 'create:person']
    # end
    #
    def configure
      yield self
      true
    end

    def run!
      OutsideRedisListener.new(:namespace => 'jupiter').run!
    end

    def message_handler=(handler)
      @message_handler = handler
    end

    def message_handler
      @message_handler || MessageHandler
    end

    def receive_message(action, name, message)
      $stdout << "RECEIVE MESSAGE!\n"
      message_handler.receive(action, name, message)
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

