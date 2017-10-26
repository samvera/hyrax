# frozen_string_literal: true

module Hyrax
  class DynamicChangeSet
    def self.new(obj, *args)
      change_set_class = if obj.is_a? Collection
                           "Hyrax::#{obj.class}ChangeSet"
                         else
                           "#{obj.class}ChangeSet"
                         end
      change_set_class.constantize.new(obj, *args)
    end
  end
end
