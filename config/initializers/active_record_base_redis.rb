require 'nest'

ActiveRecord::Base.class_eval do
  def stream
    Nest.new(self.class.name, $redis)[to_param]
  end

  def self.stream
    Nest.new(name, $redis)
  end

  def events(size=-1)
    stream[:event].lrange(0, size).map do |event_id|
      {
        action: $redis.hget("events:#{event_id}", "action"),
        timestamp: $redis.hget("events:#{event_id}", "timestamp")
      }
    end
  end

  def profile_events(size=-1)
    stream[:event][:profile].lrange(0, size).map do |event_id|
      {
        action: $redis.hget("events:#{event_id}", "action"),
        timestamp: $redis.hget("events:#{event_id}", "timestamp")
      }
    end
  end

  def create_event(action, timestamp)
    event_id = $redis.incr("events:latest_id")
    $redis.hmset("events:#{event_id}", "action", action, "timestamp", timestamp)
    event_id
  end

  def log_event(event_id)
    stream[:event].lpush(event_id)
  end

  def log_profile_event(event_id)
    stream[:event][:profile].lpush(event_id)
  end
end
