# frozen_string_literal: true
namespace :hyrax do
  desc 'Print a count of each object type'
  task count: [:environment] do
    Rails.application.eager_load!
    puts "Number of objects in the repository:"
    ActiveFedora::Base.descendants.each do |model|
      puts "  #{model}: #{model.count}"
    end
  end
end
