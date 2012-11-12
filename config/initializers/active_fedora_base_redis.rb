# Copyright © 2012 The Pennsylvania State University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'nest'

ActiveFedora::Base.class_eval do
  def stream
    Nest.new(self.class.name, $redis)[to_param]
  rescue
    nil
  end

  def self.stream
    Nest.new(name, $redis)
  rescue
    nil
  end

  def events(size=-1)
    stream[:event].lrange(0, size).map do |event_id|
      {
        action: $redis.hget("events:#{event_id}", "action"),
        timestamp: $redis.hget("events:#{event_id}", "timestamp")
      }
    end
  rescue
    []
  end

  def create_event(action, timestamp)
    event_id = $redis.incr("events:latest_id")
    $redis.hmset("events:#{event_id}", "action", action, "timestamp", timestamp)
    event_id
  rescue
    nil
  end

  def log_event(event_id)
    stream[:event].lpush(event_id)
  rescue
    nil
  end
end
