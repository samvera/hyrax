# frozen_string_literal: true
namespace :wings do
  task benchmark_save: :environment do
    # Base Case: 11.76 seconds
    Rails.logger = Logger.new(STDOUT)
    Benchmark.ips do |x|
      x.report "save a Valkyrie object" do
        save_object
      end
    end
  end
  task profile_save: :environment do
    require 'ruby-prof'
    result = RubyProf.profile do
      save_object
    end
    printer = RubyProf::CallStackPrinter.new(result)
    printer.print(File.open("tmp/save_benchmark.html", "w"), min_percent: 1)
  end

  def save_object
    persister = Hyrax.persister
    monograph = Monograph.new
    persister.save(resource: monograph)
  end
end
