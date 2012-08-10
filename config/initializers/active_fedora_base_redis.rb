require 'nest'

ActiveFedora::Base.class_eval do
  def stream
    Nest.new(self.class.name, $redis)[to_param]
  end

  def self.stream
    Nest.new(name, $redis)
  end

  def events(size=-1)
    stream[:event].lrange(0, size).map do |event_id|
      {
        action: stream.hget("events:#{event_id}", "action"),
        timestamp: stream.hget("events:#{event_id}", "timestamp")
      }
    end
  end

  def create_event(action, timestamp)
    stream.multi do
      @event_id = stream.incr("events:latest_id")
      stream.hmset("events:#{@event_id}", "action", action, "timestamp", timestamp)
    end
    @event_id.value
  end

  def log_event(event_id)
    stream[:event].lpush(event_id)
  end
end
