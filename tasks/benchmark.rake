# frozen_string_literal: true
namespace :wings do
  if ENV['IN_DOCKER'] && !Module.const_defined?(:APP_RAKEFILE)
    APP_RAKEFILE = File.expand_path("Rakefile", Pathname.new(__dir__).join("..", "..", "hyrax-webapp"))
    load 'rails/tasks/engine.rake'
  end

  task benchmark_convert: :environment do
    setup_logger

    monograph = Monograph.new
    generic_work_resource = GenericWork.new.valkyrie_resource

    Benchmark.ips do |x|
      x.report "convert a Monograph object to ActiveFedora" do
        Wings::ActiveFedoraConverter.convert(resource: monograph)
      end

      x.report "convert a derived Valkyrie object back to ActiveFedora" do
        Wings::ActiveFedoraConverter.convert(resource: generic_work_resource)
      end
    end
  end

  task benchmark_save: :environment do
    # Base Case: 1.4 / Second
    setup_logger

    persister = Hyrax.persister

    Benchmark.ips do |x|
      x.report "save a Valkyrie object" do
        save_object(persister)
      end
    end
  end
  task profile_save: :environment do
    require 'ruby-prof'
    save_object
    result = RubyProf.profile(include_threads: [Thread.current], merge_fibers: true) do
      save_object
    end
    printer = RubyProf::CallStackPrinter.new(result)
    printer.print(File.open("tmp/save_benchmark.html", "w"), min_percent: 1)
  end

  def save_object(persister)
    monograph = Monograph.new
    persister.save(resource: monograph)
  end

  def setup_logger
    $VERBOSE = nil unless ENV['RUBY_LOUD']
    Hyrax.logger.level = ENV.fetch('BM_LOG_LEVEL', :error)
  end
end
