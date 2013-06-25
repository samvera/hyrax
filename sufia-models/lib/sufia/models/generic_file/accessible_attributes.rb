module Sufia
  module GenericFile
    module AccessibleAttributes
      extend ActiveSupport::Concern
      included do
        class_attribute :_accessible_attributes
        self._accessible_attributes = {}
      end

      def accessible_attributes(role = :default)
         self.class._accessible_attributes[role] || []
      end

      # Sanitize the provided attributes using only those that are specified
      # as accessible by attr_accessor
      # @param [Hash] attributes the raw parameters
      # @param [Hash] args a hash of options
      # @option args [Symbol] :as (:default) the role to use
      # @return A sanitized hash of parameters
      def sanitize_attributes(attributes = {}, args = {})
        role = args[:as] || :default
        attributes.select { |k,v| accessible_attributes.include?(k.to_sym)}
      end

      module ClassMethods
        # Specifies a white list of model attributes that can be set via
        # mass-assignment.
        #
        # Like +attr_protected+, a role for the attributes is optional,
        # if no role is provided then :default is used. A role can be defined by
        # using the :as option.
        #
        # Mass-assignment will only set attributes in this list, to assign to
        # the rest of # attributes you can use direct writer methods. This is
        # meant to protect sensitive attributes from being overwritten by 
        # malicious users # tampering with URLs or forms. 
        #
        #   class Customer
        #     include ActiveModel::MassAssignmentSecurity
        #
        #     attr_accessor :name, :credit_rating
        #
        #     attr_accessible :name
        #     attr_accessible :name, :credit_rating, :as => :admin
        #
        #     def assign_attributes(values, options = {})
        #       sanitize_for_mass_assignment(values, options[:as]).each do |k, v|
        #         send("#{k}=", v)
        #       end
        #     end
        #   end
        #
        # When using the :default role:
        #
        #   customer = Customer.new
        #   customer.assign_attributes({ "name" => "David", "credit_rating" => "Excellent", :last_login => 1.day.ago }, :as => :default)
        #   customer.name          # => "David"
        #   customer.credit_rating # => nil
        #
        #   customer.credit_rating = "Average"
        #   customer.credit_rating # => "Average"
        #
        # And using the :admin role:
        #
        #   customer = Customer.new
        #   customer.assign_attributes({ "name" => "David", "credit_rating" => "Excellent", :last_login => 1.day.ago }, :as => :admin)
        #   customer.name          # => "David"
        #   customer.credit_rating # => "Excellent"
        #
        # Note that using <tt>Hash#except</tt> or <tt>Hash#slice</tt> in place of
        # +attr_accessible+ to sanitize attributes provides basically the same
        # functionality, but it makes a bit tricky to deal with nested attributes.
        def attr_accessible(*args)
          options = args.extract_options!
          role = options[:as] || :default

          self._accessible_attributes ||= {}

          Array.wrap(role).each do |name|
            self._accessible_attributes[name] = args.map &:to_sym
          end
        end

      end
    end
  end
end
