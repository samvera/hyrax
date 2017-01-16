module Hyrax
  module Workflow
    # Responsible for loading workflows from a data source.
    #
    # @see .load_workflows
    # @see .generate_from_json_file
    class WorkflowImporter
      class << self
        def clear_load_errors!
          self.load_errors = []
        end

        attr_reader :load_errors

        private

          attr_writer :load_errors
      end

      # @api public
      #
      # Load all the workflows in config/workflows/*.json
      # @return [TrueClass]
      def self.load_workflows
        clear_load_errors!
        Dir.glob(Rails.root.join('config', 'workflows', '*.json')) do |config|
          Rails.logger.info "Loading workflow: #{config}"
          generate_from_json_file(path: config)
        end
        true
      end

      # @api public
      #
      # Responsible for generating the work type and corresponding processing entries based on given pathname or JSON document.
      #
      # @return [Array<Sipity::Workflow>]
      def self.generate_from_json_file(path:, **keywords)
        contents = path.respond_to?(:read) ? path.read : File.read(path)
        data = JSON.parse(contents)
        importer = new(data: data, **keywords)
        workflow = importer.call
        self.load_errors ||= []
        load_errors.concat(importer.errors)

        workflow
      end

      # @param data [#deep_symbolize_keys] the configuration information from which we will generate all the data entries
      # @param schema [#call] The schema in which you will validate the data
      # @param validator [#call] The validation service for the given data and schema
      def initialize(data:, schema: default_schema, validator: default_validator)
        self.data = data
        self.schema = schema
        self.validator = validator
        validate!
      end

      private

        attr_reader :data

        def data=(input)
          @data = input.deep_symbolize_keys
        end

        attr_accessor :validator

        def default_validator
          SchemaValidator.method(:call)
        end

        attr_accessor :schema

        def default_schema
          Hyrax::Workflow::WorkflowSchema
        end

        def validate!
          validator.call(data: data, schema: schema)
        end

      public

      attr_accessor :errors

      def call
        self.errors = []
        Array.wrap(data.fetch(:workflows)).map do |configuration|
          begin
            find_or_create_from(configuration: configuration)
          rescue InvalidStateRemovalException => e
            e.states.each do |state|
              error = I18n.t('hyrax.workflow.load.state_error', workflow_name: state.workflow.name, state_name: state.name, entity_count: state.entities.count)
              Rails.logger.error(error)
              errors << error
            end
            Sipity::Workflow.find_by(name: configuration[:name])
          end
        end
      end

      private

        def find_or_create_from(configuration:)
          workflow = Sipity::Workflow.find_or_initialize_by(name: configuration.fetch(:name))
          generate_state_diagram!(workflow: workflow, actions_configuration: configuration.fetch(:actions))

          find_or_create_workflow_permissions!(
            workflow: workflow, workflow_permissions_configuration: configuration.fetch(:workflow_permissions, [])
          )
          workflow.label = configuration.fetch(:label, nil)
          workflow.description = configuration.fetch(:description, nil)
          workflow.save!
          workflow
        end

        extend Forwardable
        def_delegator WorkflowPermissionsGenerator, :call, :find_or_create_workflow_permissions!
        def_delegator SipityActionsGenerator, :call, :generate_state_diagram!

        module SchemaValidator
          # @param data [Hash]
          # @param schema [#call]
          #
          # @return true if the data validates from the schema
          # @raise Exceptions::InvalidSchemaError if the data does not validate against the schema
          def self.call(data:, schema:)
            validation = schema.call(data)
            return true unless validation.messages.present?
            raise validation.messages.inspect
          end
        end
    end
  end
end
