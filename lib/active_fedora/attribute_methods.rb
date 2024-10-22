# frozen_string_literal: true
require 'active_support/core_ext/object'
require 'active_support/core_ext/class/attribute'
require 'mutex_m'

module ActiveFedora
  module AttributeMethods
    # rubocop:disable Naming/PredicateName
    extend ActiveSupport::Concern
    include ActiveModel::AttributeMethods

    AttrNames = Module.new do
      def self.set_name_cache(name, value)
        const_name = "ATTR_#{name}"
        const_set const_name, value.dup.freeze unless const_defined? const_name
      end
    end

    RESTRICTED_CLASS_METHODS = %w[private public protected allocate new name parent superclass].freeze

    class GeneratedAttributeMethods < Module; end # :nodoc:

    module ClassMethods
      def inherited(child_class) # :nodoc:
        child_class.initialize_generated_modules
        super
      end

      def initialize_generated_modules # :nodoc:
        @generated_attribute_methods = GeneratedAttributeMethods.new { extend Mutex_m }
        @attribute_methods_generated = false
        include @generated_attribute_methods

        super
      end

      # Raises an ActiveFedora::DangerousAttributeError exception when an
      # \Active \Record method is defined in the model, otherwise +false+.
      #
      #   class Person < ActiveRecord::Base
      #     def save
      #       'already defined by Active Fedora'
      #     end
      #   end
      #
      #   Person.instance_method_already_implemented?(:save)
      #   # => ActiveFedora::DangerousAttributeError: save is defined by Active Record. Check to make sure that you don't have an attribute or method with the same name.
      #
      #   Person.instance_method_already_implemented?(:name)
      #   # => false
      def instance_method_already_implemented?(method_name)
        if dangerous_attribute_method?(method_name)
          raise DangerousAttributeError,
"#{method_name} is defined by Active Fedora. Check to make sure that you don't have an attribute or method with the same name."
        end

        if superclass == Base
          super
        else
          # If ThisClass < ... < SomeSuperClass < ... < Base and SomeSuperClass
          # defines its own attribute method, then we don't want to overwrite that.
          defined = method_defined_within?(method_name, superclass, Base) &&
                    !superclass.instance_method(method_name).owner.is_a?(GeneratedAttributeMethods)
          defined || super
        end
      end

      # A method name is 'dangerous' if it is already (re)defined by Active Fedora, but
      # not by any ancestors. (So 'puts' is not dangerous but 'save' is.)
      def dangerous_attribute_method?(name) # :nodoc:
        method_defined_within?(name, Base)
      end

      def method_defined_within?(name, klass, superklass = klass.superclass) # :nodoc:
        if klass.method_defined?(name) || klass.private_method_defined?(name)
          if superklass.method_defined?(name) || superklass.private_method_defined?(name)
            klass.instance_method(name).owner != superklass.instance_method(name).owner
          else
            true
          end
        else
          false
        end
      end

      # A class method is 'dangerous' if it is already (re)defined by Active Record, but
      # not by any ancestors. (So 'puts' is not dangerous but 'new' is.)
      def dangerous_class_method?(method_name)
        RESTRICTED_CLASS_METHODS.include?(method_name.to_s) || class_method_defined_within?(method_name, Base)
      end

      def class_method_defined_within?(name, klass, superklass = klass.superclass) # :nodoc:
        if klass.respond_to?(name, true)
          if superklass.respond_to?(name, true)
            klass.method(name).owner != superklass.method(name).owner
          else
            true
          end
        else
          false
        end
      end

      private

      # @param name [Symbol] name of the attribute to generate
      def generate_method(name)
        generated_attribute_methods.synchronize do
          define_attribute_methods name
        end
      end
    end

    included do
      initialize_generated_modules
      include Read
      include Write
      include Dirty
    end

    # Returns +true+ if the given attribute is in the attributes hash, otherwise +false+.
    #
    #   class Person < ActiveRecord::Base
    #   end
    #
    #   person = Person.new
    #   person.has_attribute?(:name)    # => true
    #   person.has_attribute?('age')    # => true
    #   person.has_attribute?(:nothing) # => false
    def has_attribute?(attr_name)
      attribute_names.include?(attr_name.to_s)
    end

    # Returns an array of names for the attributes available on this object.
    #
    #   class Person < ActiveFedora::Base
    #   end
    #
    #   person = Person.new
    #   person.attribute_names
    #   # => ["id", "created_at", "updated_at", "name", "age"]
    def attribute_names
      @local_attributes.keys
    end

    # Returns a hash of all the attributes with their names as keys and the values of the attributes as values.
    #
    #   class Person < ActiveFedora::Base
    #   end
    #
    #   person = Person.create(name: 'Francesco', age: 22)
    #   person.attributes
    #   # => {"id"=>3, "created_at"=>Sun, 21 Oct 2012 04:53:04, "updated_at"=>Sun, 21 Oct 2012 04:53:04, "name"=>"Francesco", "age"=>22}
    def attributes
      result = {}
      attribute_names.each do |name|
        result[name] = read_attribute(name)
      end
      result
    end

    # Returns an <tt>#inspect</tt>-like string for the value of the
    # attribute +attr_name+. String attributes are truncated up to 50
    # characters, Date and Time attributes are returned in the
    # <tt>:db</tt> format, Array attributes are truncated up to 10 values.
    # Other attributes return the value of <tt>#inspect</tt> without
    # modification.
    #
    #   person = Person.create!(name: 'David Heinemeier Hansson ' * 3)
    #
    #   person.attribute_for_inspect(:name)
    #   # => "\"David Heinemeier Hansson David Heinemeier Hansson ...\""
    #
    #   person.attribute_for_inspect(:created_at)
    #   # => "\"2012-10-22 00:15:07\""
    #
    #   person.attribute_for_inspect(:tag_ids)
    #   # => "[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, ...]"
    def attribute_for_inspect(attr_name)
      value = self[attr_name]

      if value.is_a?(String) && value.length > 50
        "#{value[0, 50]}...".inspect
      elsif value.is_a?(Date) || value.is_a?(Time)
        %("#{value}")
      elsif value.is_a?(Array) && value.size > 10
        inspected = value.first(10).inspect
        %(#{inspected[0...-1]}, ...])
      else
        value.inspect
      end
    end

    # Returns +true+ if the specified +attribute+ has been set by the user or by a
    # database load and is neither +nil+ nor <tt>empty?</tt> (the latter only applies
    # to objects that respond to <tt>empty?</tt>, most notably Strings). Otherwise, +false+.
    # Note that it always returns +true+ with boolean attributes.
    #
    #   class Task < ActiveRecord::Base
    #   end
    #
    #   task = Task.new(title: '', is_done: false)
    #   task.attribute_present?(:title)   # => false
    #   task.attribute_present?(:is_done) # => true
    #   task.title = 'Buy milk'
    #   task.is_done = true
    #   task.attribute_present?(:title)   # => true
    #   task.attribute_present?(:is_done) # => true
    def attribute_present?(attribute)
      value = self[attribute]
      !value.nil? && !(value.respond_to?(:empty?) && value.empty?)
    end

    # Returns the value of the attribute identified by <tt>attr_name</tt> after it has been typecast (for example,
    # "2004-12-12" in a date column is cast to a date object, like Date.new(2004, 12, 12)). It raises
    # <tt>ActiveModel::MissingAttributeError</tt> if the identified attribute is missing.
    #
    # Alias for the <tt>read_attribute</tt> method.
    #
    #   class Person < ActiveRecord::Base
    #     belongs_to :organization
    #   end
    #
    #   person = Person.new(name: 'Francesco', age: '22')
    #   person[:name] # => "Francesco"
    #   person[:age]  # => 22
    #
    #   person = Person.select('id').first
    #   person[:name]            # => ActiveModel::MissingAttributeError: missing attribute: name
    #   person[:organization_id] # => ActiveModel::MissingAttributeError: missing attribute: organization_id
    def [](attr_name)
      read_attribute(attr_name) { |n| missing_attribute(n, caller) }
    end

    # Updates the attribute identified by <tt>attr_name</tt> with the specified +value+.
    # (Alias for the protected <tt>write_attribute</tt> method).
    #
    #   class Person < ActiveFedora::Base
    #   end
    #
    #   person = Person.new
    #   person[:age] = '22'
    #   person[:age] # => 22
    #   person[:age] # => Integer
    def []=(attr_name, value)
      write_attribute(attr_name, value)
    end
  end
end
