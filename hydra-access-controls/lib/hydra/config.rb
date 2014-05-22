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
        else
          raise "Unknown key #{key}"
      end
    end

    attr_reader :permissions
    attr_accessor :user_model

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

      def embargo_release_date
        Deprecation.warn PermissionsConfig, "embargo_release_date is deprecated, use embargo.release_date instead"
        embargo.release_date
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
          when :embargo_release_date
            Deprecation.warn PermissionsConfig, "[:embargo_release_date]= is deprecated, use embargo.release_date= instead"
            embargo.release_date = value
          when :policy_class
            self.policy_class = value
          when :owner
            logger.warn "':owner' is no longer a valid configuration for Hydra. Please remove it from your configuration."
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
          when :embargo_release_date
            Deprecation.warn PermissionsConfig, "[:embargo_release_date] is deprecated, use embargo.release_date= instead"
            embargo.release_date
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
        ActiveFedora::SolrService.solr_name(*args)
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
          ActiveFedora::SolrService.solr_name(*args)
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
          ActiveFedora::SolrService.solr_name(*args)
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
