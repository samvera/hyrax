# frozen_string_literal: true
RSpec::Support.require_rspec_core "formatters/base_text_formatter"
class LoggingFormatter < RSpec::Core::Formatters::ProgressFormatter
  RSpec::Core::Formatters.register self, :example_started, :example_passed, :dump_profile
  def initialize(output)
    @profile = []
    reset!
    ActiveSupport::Notifications.subscribe("http.ldp", method(:record_request))
    super
  end

  def record_request(*_unused, data)
    @request_count += 1
    @request_count_by_name[data[:name]] += 1
  end

  def example_passed(passed)
    super
    @profile << { description: passed.example.full_description,
                  count: @request_count,
                  location: passed.example.location,
                  count_by_name: @request_count_by_name }
  end

  def example_started(_passed)
    reset!
  end

  def reset!
    @request_count = 0
    @request_count_by_name = { 'HEAD' => 0,
                               'GET' => 0,
                               'POST' => 0,
                               'DELETE' => 0,
                               'PUT' => 0,
                               'PATCH' => 0 }
  end

  def dump_profile(profile)
    dump_most_ldp_exampes(profile)
    output.puts ""
    dump_slowest_examples(profile)
  end

  private

  def dump_most_ldp_exampes(_prof)
    output.puts "Examples with the most LDP requests"
    top = @profile.sort_by { |hash| hash[:count] }.last(10)
    top.each do |hash|
      result = hash[:count_by_name].select { |_, v| v.positive? }
      next if result.empty?
      output.puts "  #{hash[:description]}"
      output.puts "    #{hash[:location]}"
      output.puts "    Total LDP: #{hash[:count]} #{result}"
    end
  end

  def dump_slowest_examples(profile)
    output.puts "Slowest examples"
    profile.slowest_examples.each do |slowest_example|
      output.puts "  #{slowest_example.full_description}"
      output.puts "    #{slowest_example.location}"
      output.puts "    #{slowest_example.execution_result.run_time} seconds"
    end
  end
end
