# frozen_string_literal: true

module Hyrax
  module Action
    ##
    # @since 5.0.0
    # @api public
    #
    # Encapsulating the logic of several interacting objects.  Namely the idea of using a form to
    # {#validate} given parameters then to {#perform} the action by leveraging the {#transactions}'s
    # {#transaction_name} configured with appropriate {#step_args} and ultimately providing the
    # {#form} to then perform that work.
    class CreateValkyrieWork
      ##
      # @!group Class Attributes
      #
      # @!attribute transaction_name
      #   @return [String] the name of the transaction that we call for the CreateValkyrieWorkAction.
      class_attribute :transaction_name, default: 'change_set.create_work'
      # @!endgroup Class Attributes
      ##

      ##
      # @param form [Object] the form that we'll use for validation and performing the action.
      # @param transactions [Hyrax::Transactions::Container] the transactions
      # @param user [User] the person performing the action
      # @param params [Hash] the contextual parameters for the action; ApplicationController#params
      #        if you will.
      # @param work_attribute_key [String] the name of the key within the params that contains
      #        the work's attributes
      def initialize(form:, transactions:, user:, params:, work_attributes_key:)
        @form = form
        @transactions = transactions
        @user = user
        @params = params
        @work_attributes_key = work_attributes_key
        @work_attributes = @params.fetch(work_attributes_key, {})
      end

      attr_reader :form, :transactions, :user, :parent_id, :work_attributes, :uploaded_files, :params, :work_attributes_key

      ##
      # @api public
      # @return [TrueClass] when the object is valid.
      # @return [FalseClass] when the object is valid.
      def validate
        form.validate(work_attributes)
      end

      ##
      # @api public
      # @return [#value_or] the resulting created work, when successful.  When not successful, the
      #         returned value call the given block.
      def perform
        transactions[transaction_name].with_step_args(**step_args).call(form)
      end

      ##
      # @api public
      #
      # @return [Hash<String,Hash>] the step args to use for the given {#transactions}'s
      #         {.transaction_name}
      def step_args
        {
          'work_resource.add_to_parent' => { parent_id: params[:parent_id], user: user },
          'work_resource.add_file_sets' => { uploaded_files: uploaded_files, file_set_params: work_attributes[:file_set] },
          'change_set.set_user_as_depositor' => { user: user },
          'work_resource.change_depositor' => { user: ::User.find_by_user_key(form.on_behalf_of) },
          'work_resource.save_acl' => { permissions_params: form.input_params["permissions"] }
        }
      end

      # rubocop:disable Lint/DuplicateMethods
      def uploaded_files
        UploadedFile.find(params.fetch(:uploaded_files, []))
      end
      # rubocop:enable Lint/DuplicateMethods
    end
  end
end
