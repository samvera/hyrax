module CurationConcerns
  class Operation < ActiveRecord::Base
    PENDING = 'pending'.freeze
    PERFORMING = 'performing'.freeze
    FAILURE = 'failure'.freeze
    SUCCESS = 'success'.freeze

    acts_as_nested_set
    define_callbacks :success, :failure
    belongs_to :user, class_name: '::User'

    # If this is a batch job (has children), check to see if all the children are complete
    def rollup_status
      with_lock do
        stats = children.pluck(:status)
        return if stats.include?(PENDING) || stats.include?(PERFORMING)
        return fail! if stats.include?(FAILURE)
        success!
      end
    end

    def success!
      run_callbacks :success do
        update(status: SUCCESS)
        parent.rollup_status if parent
      end
    end

    def fail!(message = nil)
      run_callbacks :failure do
        update(status: FAILURE, message: message)
        parent.rollup_status if parent
      end
    end

    def performing!
      update(status: PERFORMING)
    end

    def pending_job(job)
      update(job_class: job.class.to_s, job_id: job.job_id, status: CurationConcerns::Operation::PENDING)
    end
  end
end
