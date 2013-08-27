module Sufia
  module GenericFile
    module Visibility
      extend ActiveSupport::Concern
      extend Deprecation
      include ActiveModel::Dirty

      included do
        define_attribute_methods :visibility
      end

      def visibility= (value)
        # only set explicit permissions
        case value
        when "open"
          public_visibility!
        when "psu"
          registered_visibility!
        when "restricted" 
          private_visibility!
        end
      end

      def public_visibility!
        visibility_will_change! unless visibility == 'public'
        self.datastreams["rightsMetadata"].permissions({:group=>"public"}, "read")
      end

      def registered_visibility!
        visibility_will_change! unless visibility == 'registered'
        self.datastreams["rightsMetadata"].permissions({:group=>"registered"}, "read")
        self.datastreams["rightsMetadata"].permissions({:group=>"public"}, "none")
      end

      def private_visibility!
        visibility_will_change! unless visibility == 'private'
        self.datastreams["rightsMetadata"].permissions({:group=>"registered"}, "none")
        self.datastreams["rightsMetadata"].permissions({:group=>"public"}, "none")
      end

      def visibility
        if read_groups.include? 'public'
          'public'
        elsif read_groups.include? 'registered'
          'registered'
        else
          'private'
        end
      end

      def set_visibility(visibility)
        Deprecation.warn Permissions, "set_visibility is deprecated, use visibility= instead.  set_visibility will be removed in sufia 3.0", caller
        self.visibility= visibility
      end
    end
  end
end


