# frozen_string_literal: true
namespace :wings do
  APP_RAKEFILE = File.expand_path("Rakefile", Pathname.new(__dir__).join("..", "..", "hyrax-webapp"))
  load 'rails/tasks/engine.rake'
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
    result = RubyProf.profile(include_threads: [Thread.current], merge_fibers: true) do
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
