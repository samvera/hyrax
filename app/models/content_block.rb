class ContentBlock < ActiveRecord::Base
  MARKETING  = 'marketing_text'.freeze
  RESEARCHER = 'featured_researcher'.freeze
  ANNOUNCEMENT = 'announcement_text'.freeze

  def self.marketing_text
    find_or_create_by(name: MARKETING)
  end

  def self.marketing_text=(value)
    marketing_text.update(value: value)
  end

  def self.announcement_text
    find_or_create_by(name: ANNOUNCEMENT)
  end

  def self.announcement_text=(value)
    announcement_text.update(value: value)
  end

  def self.recent_researchers
    where(name: RESEARCHER).order('created_at DESC')
  end

  def self.featured_researcher
    recent_researchers.first_or_create(name: RESEARCHER)
  end

  def self.featured_researcher=(value)
    create(name: RESEARCHER, value: value)
  end

  def self.external_keys
    { RESEARCHER => 'User' }
  end

  def external_key_name
    self.class.external_keys.fetch(name) { 'External Key' }
  end
end
