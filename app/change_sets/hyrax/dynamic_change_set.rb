# frozen_string_literal: true

module Hyrax
  class DynamicChangeSet
    def self.new(obj, *args)
      "#{obj.class}ChangeSet".constantize.new(obj, *args)
    end
  end
end
