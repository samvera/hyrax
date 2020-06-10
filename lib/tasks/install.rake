# frozen_string_literal: true
namespace :hyrax do
  namespace :install do
    desc 'Copy migrations from Hyrax to application'
    task migrations: :environment do
      Hyrax::DatabaseMigrator.copy
    end
  end
end
