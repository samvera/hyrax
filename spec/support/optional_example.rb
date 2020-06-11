# frozen_string_literal: true
module OptionalExample
  RSpec.configure do |config|
    config.after do |example|
      if example.metadata[:optional] && (RSpec::Core::Pending::PendingExampleFixedError === example.display_exception) # rubocop:disable Style/CaseEquality
        ex = example.display_exception
        example.display_exception = nil
        example.execution_result.pending_exception = ex
      end
    end
  end

  def optional(message)
    RSpec.current_example.metadata[:optional] = true
    pending(message)
  end
end
