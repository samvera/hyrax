class ContentBlock < ActiveRecord::Base
  MARKETING  = 'marketing_text'.freeze
  RESEARCHER = 'featured_researcher'.freeze
  ANNOUNCEMENT = 'announcement_text'.freeze

  def self.recent_researchers
    where(name: RESEARCHER).order('created_at DESC')
  end

  def self.featured_researcher
    recent_researchers.first
  end

  def self.external_keys
    { RESEARCHER => 'User' }
  end

  def external_key_name
    self.class.external_keys.fetch(name) { 'External Key' }
  end
end
