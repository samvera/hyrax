# frozen_string_literal: true
require 'rails/generators'

class Hyrax::HealthCheckGenerator < Rails::Generators::Base
  desc """
    Installs Hyrax's default health check endpoints at `/healthz`.
  """

  source_root File.expand_path('../templates', __FILE__)

  def add_to_gemfile
    gem 'okcomputer', '~> 1.18'
  end
end
