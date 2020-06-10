# frozen_string_literal: true
module StatisticHelper
  def statistic_date(date)
    date.to_datetime.to_i * 1000
  end

  RSpec.configure do |config|
    config.include StatisticHelper
  end
end
