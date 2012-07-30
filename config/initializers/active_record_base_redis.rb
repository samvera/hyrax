require 'nest'

ActiveRecord::Base.class_eval do
  def rdb
    Nest.new(self.class.name, $redis)[to_param]
  end

  def self.rdb
    Nest.new(name, $redis)
  end
end
