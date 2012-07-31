require 'nest'

ActiveRecord::Base.class_eval do
  def stream
    Nest.new(self.class.name, $redis)[to_param]
  end

  def self.stream
    Nest.new(name, $redis)
  end

  def events
    stream[:event].zrevrange(0, -1, withscores: true)
  end
end
