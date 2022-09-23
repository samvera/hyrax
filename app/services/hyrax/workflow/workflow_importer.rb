# frozen_string_literal: true
module Hyrax
  module Workflow
    # Responsible for loading workflows from a data source.
    #
    # @see .load_workflows
    # @see .generate_from_json_file
    class WorkflowImporter
      class_attribute :default_logger
      self.default_logger = Hyrax.logger
      class_attribute :path_to_workflow_files
      self.path_to_workflow_files = Rails.root.join('config', 'workflows', '*.json')

      class << self
        def clear_load_errors!
          self.load_errors = []
        end

        attr_reader :load_errors

        private

        attr_writer :load_errors
      end

      # @api public
      # Load all of the workflows for the given permission_template
      #
      # @param [Hyrax::PermissionTemplate] permission_template
      # @param [#info, #debug, #warning, #fatal] logger - By default this is Hyrax::Workflow::WorkflowImporter.default_logger
      # @return [TrueClass] if one or more workflows were loaded
      # @return [FalseClass] if no workflows were loaded
      # @note I'd like to deprecate .load_workflows but for now that is beyond the scope of what I'm after. So I will use its magic instead
      def self.load_workflow_for(permission_template:, logger: default_logger)
        workflow_config_filenames = Dir.glob(path_to_workflow_files)
        if workflow_config_filenames.none?
          logger.info("Unable to load workflows for #{permission_template.class} ID=#{permission_template.id}. No workflows were found in #{path_to_workflow_files}")
          return false
        end
        workflow_config_filenames.each do |config|
          logger.info "Loading permission_template ID=#{permission_template.id} with workflow config #{config}"
          generate_from_json_file(path: config, permission_template: permission_template, logger: default_logger)
        end
        true
      end

      # @api public
      #
      # Load all the workflows in config/workflows/*.json for each of the permission templates
      # @param  [#each] permission_templates - An enumerator of permission templates (by default Hyrax::PermissionTemplate.all)
      # @return [TrueClass]
      def self.load_workflows(permission_templates: Hyrax::PermissionTemplate.all, **kwargs)
        clear_load_errors!
        Array.wrap(permission_templates).each do |permission_template|
          load_workflow_for(permission_template: permission_template, **kwargs)
        end
        true
      end

      # @api public
      #
      # Responsible for generating the work type and corresponding processing entries based on given pathname or JSON document.
      #
      # @param [#read or String] path - the location on the file system that can be read
      # @param [Hyrax::PermissionTemplate] permission_template - the permission_template that will be associated with each of these entries
      # @return [Array<Sipity::Workflow>]
      def self.generate_from_json_file(path:, permission_template:, **keywords)
        contents = path.respond_to?(:read) ? path.read : File.read(path)
        data = JSON.parse(contents)
        generate_from_hash(data: data, permission_template: permission_template, **keywords)
      end

      # @api public
      #
      # Responsible for generating the work type and corresponding processing entries based on given pathname or JSON document.
      #
      # @param [#deep_symbolize_keys] data - the configuration information from which we will generate all the data entries
      # @param [Hyrax::PermissionTemplate] permission_template - the permission_template that will be associated with each of these entries
      # @return [Array<Sipity::Workflow>]
      def self.generate_from_hash(data:, permission_template:, **keywords)
        importer = new(data: data, permission_template: permission_template, **keywords)
        workflows = importer.call
        self.load_errors ||= []
        load_errors.concat(importer.errors)
        workflows
      end

      # @param [#deep_symbolize_keys] data - the configuration information from which we will generate all the data entries
      # @param [Hyrax::PermissionTemplate] permission_template - the permission_template that will be associated with each of these entries
      # @param [#call] schema - The schema in which you will validate the data
      # @param [#call] validator - The validation service for the given data and schema
      # @param [#debug, #info, #fatal, #warning] logger - The logger to capture any meaningful output
      def initialize(data:, permission_template:, schema: default_schema, validator: default_validator, logger: default_logger)
        self.data = data
        self.schema = schema
        self.validator = validator
        self.permission_template = permission_template
        @logger = logger
        validate!
      end

      private

      attr_reader :data, :logger

      def data=(input)
        @data = input.deep_symbolize_keys
      end

      attr_accessor :validator, :permission_template, :schema

      def default_validator
        SchemaValidator.method(:call)
      end

      def default_schema
        Hyrax::Workflow::WorkflowSchema.new
      end

      def validate!
        validator.call(data: data, schema: schema, logger: logger)
      end

      public

      attr_accessor :errors

      def call
        self.errors = []
        Array.wrap(data.fetch(:workflows)).map do |configuration|
          find_or_create_from(configuration: configuration)
        rescue InvalidStateRemovalException => e
          e.states.each do |state|
            error = I18n.t('hyrax.workflow.load.state_error', workflow_name: state.workflow.name, state_name: state.name, entity_count: state.entities.count)
            Hyrax.logger.error(error)
            errors << error
          end
          Sipity::Workflow.find_by(name: configuration[:name])
        end
      end

      private

      def find_or_create_from(configuration:)
        workflow = Sipity::Workflow.find_or_initialize_by(name: configuration.fetch(:name), permission_template: permission_template)
        generate_state_diagram!(workflow: workflow, actions_configuration: configuration.fetch(:actions))

        find_or_create_workflow_permissions!(
          workflow: workflow, workflow_permissions_configuration: configuration.fetch(:workflow_permissions, [])
        )
        workflow.label = configuration.fetch(:label, nil)
        workflow.description = configuration.fetch(:description, nil)
        workflow.allows_access_grant = configuration.fetch(:allows_access_grant, nil)
        workflow.save!
        logger.info(%(Loaded Sipity::Workflow "#{workflow.name}" for #{permission_template.class} ID=#{permission_template.id}))
        workflow
      end

      extend Forwardable
      def_delegator WorkflowPermissionsGenerator, :call, :find_or_create_workflow_permissions!
      def_delegator SipityActionsGenerator, :call, :generate_state_diagram!

      module SchemaValidator
        # @param data [Hash]
        # @param schema [#call]
        #
        # @return [Boolean] true if the data validates from the schema
        # @raise [RuntimeError] if the data does not validate against the schema
        def self.call(data:, schema:, logger:)
          result = schema.call(data)
          return true if result.success?
          message = format_message(result)
          logger.error(message)
          raise message
        end

        ##
        # @param result [Dry::Validation::Result]
        #
        # @return [String]
        def self.format_message(result)
          messages = result.errors(full: true).map do |msg|
            "Error on workflow entry #{msg.path}\n\t#{msg.text}\n\tGot: #{msg.input || '[no entry]'}"
          end

          messages << "Input was:\n\t#{result.to_h}"
          messages.join("\n")
        end
      end
    end
  end
end
