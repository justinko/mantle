module Mantle
  class CatchUp
    KEY = "mantle:catch_up"
    HOURS_TO_KEEP = 6
    CLEANUP_EVERY_MINUTES = 5

    attr_accessor :redis, :message_bus_channels
    attr_reader :key

    def initialize
      @redis = Mantle.configuration.message_bus_redis
      @message_bus_channels = Mantle.channels
      @key = KEY
    end

    def add_message(channel, message, now = Time.now.utc.to_f)
      json = serialize_payload(channel, message)
      redis.zadd(key, now, json)
      Mantle.logger.debug("Added message to catch up list for channel: #{channel}")
      now
    end

    def enqueue_clear_if_ready
      now = Time.now.utc.to_f
      five_minutes_ago = now - (CLEANUP_EVERY_MINUTES * 60.0)
      last_cleanup = Mantle::LocalRedis.last_catch_up_cleanup_at

      if last_cleanup.nil? || last_cleanup < five_minutes_ago
        Mantle::Workers::CatchUpCleanupWorker.perform_async
      end
    end

    def clear_expired
      max_time_to_clear = hours_ago_in_seconds(HOURS_TO_KEEP)
      redis.zremrangebyscore(key, 0, max_time_to_clear)
    end

    def catch_up
      raise Mantle::Error::MissingRedisConnection unless redis

      if last_success_time.nil?
        Mantle.logger.info("Skipping catch up because of missing last processed time...")
        return
      end

      Mantle.logger.info("Catching up from time: #{last_success_time}")

      payloads_with_time = redis.zrangebyscore(key, last_success_time, 'inf', with_scores: true)
      route_messages(payloads_with_time) if payloads_with_time.any?
    end

    def last_success_time
      LocalRedis.last_message_successfully_received_at
    end

    def route_messages(payloads_with_time)
      payloads_with_time.each do |payload_with_time|
        payload, time = payload_with_time
        channel, message = deserialize_payload(payload)

        if message_bus_channels.include?(channel)
          Mantle::MessageRouter.new(channel, message).route
        end
      end
    end

    def deserialize_payload(payload)
      JSON(payload).values_at 'channel', 'message'
    end

    def hours_ago_in_seconds(hours)
      hour_seconds = 60 * 60 * hours
      Time.now.utc.to_f - hour_seconds
    end

    private

    def serialize_payload(channel, message)
      JSON({channel: channel, message: message})
    end
  end
end
