RSpec.shared_examples 'a Hyrax workflow method' do
  before do
    raise 'workflow_method must be set with `let(:workflow_method)`' unless
      defined? workflow_method
  end

  subject { workflow_method }
  let(:expected_call_method_keywords){ [:target, :comment, :user] }


  describe '#call' do
    it "handles the :target, :comment, and :user keywords (but not other parameters that don't have defaults)" do
      parameters = subject.method(:call).parameters
      parameter_types = parameters.map(&:first)
      errors = []

      # If we have splat *args or **kwargs, the path is different
      if parameter_types.include?(:keyrest) || parameter_types.include?(:rest)
        parameters.each do |parameter|
          next if parameter.first == :keyrest
          next if parameter.first == :opt
          next if parameter.first == :key
          next if parameter.first == :rest
          next if expected_call_method_keywords.include?(parameter.last)
          errors << "Unexpected keyword argument: #{parameter.last.inspect} for #{workflow_method}"
        end
      else
        # We don't have splat args and need to make sure that each keyword parameter are handled
        must_have = expected_call_method_keywords.clone
        parameters.each do |parameter|
          next if parameter.first == :opt
          next if parameter.first == :key
          next if parameter.first == :rest
          if expected_call_method_keywords.include?(parameter.last)
            must_have -= [parameter.last]
          end
          errors << "Unexpected keyword argument: #{parameter.last.inspect} for #{workflow_method}"
        end
        if must_have.any?
          errors << "Missing keyword arguments for: #{must_have}"
        end
      end
      expect(errors).to(be_empty, errors.join("\n"))
    end
  end
end
