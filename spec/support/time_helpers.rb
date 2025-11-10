# frozen_string_literal: true

RSpec.configure do |config|
  # Include ActiveSupport::Testing::TimeHelpers in all examples
  config.include ActiveSupport::Testing::TimeHelpers

  # Hook for :frozen_time tag - freezes time to Nov 17, 2011 14:23 EST
  config.around(:example, :frozen_time) do |example|
    # Nov 17, 2011 14:23 EST (UTC-5)
    frozen_time = Time.zone.parse("2011-11-17 19:23:00 UTC")

    travel_to(frozen_time) do
      example.run
    end
  end
end