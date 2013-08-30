module ActiveRecord
  module DeprecatedAttrAccessible
    extend ActiveSupport::Concern
    module ClassMethods
      def deprecated_attr_accessible(*args)
        if Rails::VERSION::MAJOR < 4 || defined?(ProtectedAttributes)
          ActiveSupport::Deprecation.warn("deprecated_attr_accessible  is, wait for it, deprecated. It will be removed when Sufia stops support Rails 3.")
          attr_accessible(*args)
        end
      end
    end
  end
end
ActiveRecord::Base.class_eval do
  include ActiveRecord::DeprecatedAttrAccessible
end
