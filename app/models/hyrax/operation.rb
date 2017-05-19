module Hyrax
  # The database storage of inter-related jobs and their states.
  class Operation < ActiveRecord::Base
    PENDING = 'pending'.freeze
    PERFORMING = 'performing'.freeze
    FAILURE = 'failure'.freeze
    SUCCESS = 'success'.freeze

    enum(
      status: {
        FAILURE => FAILURE,
        PENDING => PENDING,
        PERFORMING => PERFORMING,
        SUCCESS => SUCCESS
      }
    )

    self.table_name = 'curation_concerns_operations'
    acts_as_nested_set
    define_callbacks :success, :failure
    belongs_to :user,
               optional: true,
               class_name: '::User'

    # If this is a batch job (has children), check to see if all the children are complete
    # @see #fail! when none of the children are in a PENDING nor PERFORMING state but at least one is in a FAILURE state
    # @see #success! none of the children are in a PENDING, PERFORMING, nor FAILURE state
    def rollup_status
      with_lock do
        # We don't need all of the status of the children, just need to see
        # if there is at least one PENDING, PERFORMING, or FAILURE.
        # With this change, it doesn't matter if we have 10_000 children or 1, we will only ever get
        # back an that is no longer than the total number of possible status values. Is it necessary?
        # No, but there is no need to instantiate an array of all of those values.
        stats = children.select(:status).distinct.pluck(:status)
        return if stats.include?(PENDING) || stats.include?(PERFORMING)
        return fail! if stats.include?(FAILURE)
        success!
      end
    end

    # Mark this operation as a SUCCESS. If this is a child operation, roll up to
    # the parent any failures.
    #
    # @see Hyrax::Operation::SUCCESS
    # @see #rollup_status
    # @note This will run any registered :success callbacks
    # @todo Where are these callbacks defined? Document this
    def success!
      run_callbacks :success do
        update(status: SUCCESS)
        parent.rollup_status if parent
      end
    end

    # Mark this operation as a FAILURE. If this is a child operation, roll up to
    # the parent any failures.
    #
    # @param [String, nil] message - record any failure message
    # @see Hyrax::Operation::FAILURE
    # @see #rollup_status
    # @note This will run any registered :success callbacks
    # @todo Where are these callbacks defined? Document this
    def fail!(message = nil)
      run_callbacks :failure do
        update(status: FAILURE, message: message)
        parent.rollup_status if parent
      end
    end

    # Sets the operation status to PERFORMING
    # @see Hyrax::Operation::PERFORMING
    def performing!
      update(status: PERFORMING)
    end

    # Sets the operation status to PENDING
    # @param [#class, #job_id] job - The job associated with this operation
    # @see Hyrax::Operation::PENDING
    def pending_job(job)
      update(job_class: job.class.to_s, job_id: job.job_id, status: Hyrax::Operation::PENDING)
    end
  end
end
