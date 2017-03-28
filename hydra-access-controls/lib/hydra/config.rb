module Hydra
  class Config
    def initialize
      @permissions = PermissionsConfig.new
      @user_model = 'User'
    end

    def []= key, value
      case key
        when :permissions
          self.permissions = value
        when :user_model
          self.user_model = value
        when :id_to_resource_uri
          self.id_to_resource_uri = value
        else
          raise "Unknown key"
      end
    end

    def [] key
      case key
        when :permissions
          permissions
        when :user_model
          user_model
        when :id_to_resource_uri
          id_to_resource_uri
        else
          raise "Unknown key #{key}"
      end
    end

    attr_reader :permissions
    attr_writer :id_to_resource_uri, :user_key_field
    attr_accessor :user_model

    def user_key_field
      @user_key_field || default_user_key_field
    end

    def default_user_key_field
      Deprecation.warn(self, "You must set 'config.user_key_field = Devise.authentication_keys.first' in your config/initializer/hydra_config.rb file. The default value will be removed in hydra-access-controls 12")
      Devise.authentication_keys.first
    end

    # This is purely used for translating an ID to user-facing URIs not used for
    # persistence. Useful for storing RDF in Fedora but displaying their
    # subjects in content negotiation as local to the application.
    #
    # @return [Lambda] a method to convert ID to a URI
    def id_to_resource_uri
      @id_to_resource_uri ||= lambda { |id, _graph| ActiveFedora::Base.translate_id_to_uri.call(id) }
    end

    def permissions= values
      @permissions.merge! values
    end

    class PermissionsConfig
      attr_accessor :policy_class, :embargo, :lease
      def initialize
        @values = {}
        [:discover, :read, :edit].each do |key|
          @values[key] = GroupPermission.new(
            group:      solr_name("#{prefix}#{key}_access_group", :symbol),
            individual: solr_name("#{prefix}#{key}_access_person", :symbol))
        end
        @embargo = EmbargoConfig.new({}, prefix: prefix)
        @lease = LeaseConfig.new({}, prefix: prefix)
      end

      def merge! values
        values.each {|k, v| self[k] = v }
      end

      def []= key, value
        case key
          when :discover, :read, :edit
            self.assign_value key, value
          when :inheritable
            inheritable.merge! value
          when :policy_class
            self.policy_class = value
          when :owner
            Rails.logger.warn "':owner' is no longer a valid configuration for Hydra. Please remove it from your configuration."
          else
            raise "Unknown key `#{key.inspect}`"
        end
      end

      def [] key
        case key
          when :discover, :read, :edit
            @values[key]
          when :inheritable
            inheritable
          when :policy_class
            @policy_class
          else
            raise "Unknown key #{key}"
        end
      end

      def inheritable
        @inheritable ||= InheritablePermissionsConfig.new
      end

      def discover
        @values[:discover]
      end

      def read
        @values[:read]
      end

      def edit
        @values[:edit]
      end

      def discover= val
        assign_value :discover, val
      end

      def read= val
        assign_value :read, val
      end

      def edit= val
        assign_value :edit, val
      end

      protected

      def prefix
      end

      def assign_value key, val
        @values[key].merge!(val)
      end

      def solr_name(*args)
        ActiveFedora.index_field_mapper.solr_name(*args)
      end

      class EmbargoConfig
        attr_accessor :release_date, :visibility_during, :visibility_after, :history
        def initialize(values = {}, attributes={prefix:''})
          @release_date = solr_name("#{attributes[:prefix]}embargo_release_date", :stored_sortable, type: :date)
          @visibility_during = solr_name("visibility_during_embargo", :symbol)
          @visibility_after = solr_name("visibility_after_embargo", :symbol)
          @history = solr_name("embargo_history", :symbol)
        end

        def solr_name(*args)
          ActiveFedora.index_field_mapper.solr_name(*args)
        end
      end

      class LeaseConfig
        attr_accessor :expiration_date, :visibility_during, :visibility_after, :history
        def initialize(values = {}, attributes={prefix:''})
          @expiration_date = solr_name("#{attributes[:prefix]}lease_expiration_date", :stored_sortable, type: :date)
          @visibility_during = solr_name("visibility_during_lease", :symbol)
          @visibility_after = solr_name("visibility_after_lease", :symbol)
          @history = solr_name("lease_history", :symbol)
        end

        def solr_name(*args)
          ActiveFedora.index_field_mapper.solr_name(*args)
        end
      end

      class GroupPermission
        attr_accessor :group, :individual
        def initialize(values = {})
          merge! values
        end
        def merge! values
          @group = values[:group]
          @individual = values[:individual]
        end
        def [] key
          case key
            when :group, :individual
              send key
            else
              raise "Unknown key"
          end
        end
      end
    end

    class InheritablePermissionsConfig < PermissionsConfig
      protected
        def prefix
          'inheritable_'
        end
    end
  end
end
