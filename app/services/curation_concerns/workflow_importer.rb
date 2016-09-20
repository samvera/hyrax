module CurationConcerns
  class WorkflowImporter
    # Responsible for generating the work type and corresponding processing entries based on given pathname or JSON document.
    def self.generate_from_json_file(path:, **keywords)
      contents = path.respond_to?(:read) ? path.read : File.read(path)
      data = JSON.parse(contents)
      new(data: data, **keywords).call
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
        WorkTypeSchema
      end

      def validate!
        validator.call(data: data, schema: schema)
      end

    public

    def call
      Array.wrap(data.fetch(:work_types)).each do |configuration|
        find_or_create_from(configuration: configuration)
      end
    end

    private

      def find_or_create_from(configuration:)
        FindOrCreateWorkType.call(name: configuration.fetch(:name)) do |_work_type, strategy, _initial_strategy_state|
          find_or_create_strategy_permissions!(
            strategy: strategy, strategy_permissions_configuration: configuration.fetch(:strategy_permissions, [])
          )
          generate_state_diagram(strategy: strategy, actions_configuration: configuration.fetch(:actions))
          generate_state_emails(strategy: strategy, state_emails_configuration: configuration.fetch(:state_emails, []))
        end
      end

      extend Forwardable
      def_delegator WorkflowPermissionsGenerator, :call, :find_or_create_workflow_permissions!
      def_delegator SipityActionsGenerator, :call, :generate_state_diagram

      def generate_state_emails(strategy:, state_emails_configuration:)
        Array.wrap(state_emails_configuration).each do |configuration|
          scope = configuration.fetch(:state)
          reason = configuration.fetch(:reason)
          Array.wrap(configuration.fetch(:emails)).each do |email_configuration|
            email_name = email_configuration.fetch(:name)
            recipients = email_configuration.slice(:to, :cc, :bcc)
            DataGenerators::EmailNotificationGenerator.call(
              strategy: strategy, scope: scope, email_name: email_name, recipients: recipients, reason: reason
            )
          end
        end
      end
  end
end
