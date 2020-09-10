# frozen_string_literal: true
module Hyrax
  module Forms
    # @deprecated This class should be removed when we switch to
    #   Valkyrie::ChangeSet instead of Hydra::Forms.
    #
    # This object is responsible for exposing the user submitted
    # params from a failed POST/PUT/PATCH.
    #
    # @see https://github.com/samvera/hyrax/issues/3978
    class FailedSubmissionFormWrapper < SimpleDelegator
      # @param form
      # @param input_params [ActionController::Parameters]
      #
      # @param permitted_params [Hash] this likely comes from a class
      #        method on the given form.  It's used for enforcing
      #        strong parameters.  It's more of a schema for what the
      #        input parameters should be.  Why not rely on the
      #        form.class.permitted_params?  This is a violation of
      #        the Law of Demeter, and due to object delegation, the
      #        form.class may be a delegate class, and not the one
      #        that has permitted_params.
      #
      # @see Hyrax::WorkForm.build_permitted_params
      def initialize(form:, input_params:, permitted_params: nil)
        @form = form
        super(@form)
        @input_params = input_params
        @exposed_params = {}
        @permitted_params = permitted_params || __default_permitted_params__(form: form)
        build_exposed_params!
      end

      # Yes, I don't want to delegate class to the form, but based on
      # past experiences, there are times where SimpleForm requests
      # class.model_name and that had better align with the underlying
      # form.
      #
      # Upon testing, when I don't have this method, the Javascript
      # for "Requirements" on the new form will not properly
      # acknowledge that we have re-filled the HTML form with the
      # submitted non-file fields.
      def class
        @form.class
      end

      def model_name
        @form.model_name
      end

      def to_model
        self
      end

      def inspect
        "Hyrax::Forms::FailedSubmissionFormWrapper(#{@form})"
      end

      def [](key)
        if @exposed_params.key?(key)
          @exposed_params.fetch(key)
        else
          super
        end
      end

      private

      def method_missing(method_name, *args, &block)
        if @exposed_params.key?(method_name)
          @exposed_params.fetch(method_name)
        else
          super
        end
      end

      def respond_to_missing?(method_name, *args)
        return true if @exposed_params.key?(method_name)
        super
      end

      def build_exposed_params!
        @permitted_params.each do |permitted_param|
          case permitted_param
          when ::Symbol
            @exposed_params[permitted_param] = @input_params.fetch(permitted_param) if @input_params.key?(permitted_param)
          when ::Hash
            permitted_param.each do |key, value_schema|
              build_exposed_param_hash_element!(key: key, value_schema: value_schema)
            end
          end
        end
      end

      def build_exposed_param_hash_element!(key:, value_schema:)
        # The input may not include the given key, so don't attempt a fetch.
        return unless @input_params.key?(key)
        # I don't have a non-Array example of what this value_schema could be.
        return unless value_schema.is_a?(::Array)
        if value_schema.empty?
          @exposed_params[key] = ::Array.wrap(@input_params.fetch(key))
        elsif value_schema.is_a?(::Array)
          # We're expecting nested attributes which will have the form:
          # { "0" => <Hash with value_schema as keys>, "1" => <Hash with value_schema as keys> }
          hash = {}
          @input_params.fetch(key).each_pair do |nested_key, nested_value|
            hash[nested_key] = nested_value.slice(*value_schema)
          end
          @exposed_params[key] = hash
        end
      end

      # This method is specifically named __default_permitted_params__
      # because the form object may well have a
      # default_permitted_params; I know it's class most certainly
      # does.
      #
      # In running tests, I'm seeing that in some cases a form object
      # has an instance method for permitted_params, other times, a
      # form object has a class method for permitted_params, and
      # though I haven't seen it in specs, I do see that forms have a
      # build_permitted_params method.
      def __default_permitted_params__(form:)
        if form.respond_to?(:permitted_params)
          form.permitted_params
        elsif form.class.respond_to?(:permitted_params)
          form.class.permitted_params
        elsif form.class.respond_to?(:build_permitted_params)
          form.class.build_permitted_params
        else
          raise ArgumentError, "Unable to extract a suitable permitted_params from #{form.inspect}"
        end
      end
    end
  end
end
