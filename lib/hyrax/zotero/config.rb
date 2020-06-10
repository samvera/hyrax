# frozen_string_literal: true
module Hyrax
  module Zotero
    def self.config
      @config ||= reload_config!
    end

    def self.reload_config!
      @config = YAML.safe_load(ERB.new(IO.read(Rails.root.join('config', 'zotero.yml'))).result)['zotero']
    end

    def self.publications_url(zotero_userid)
      "/users/#{zotero_userid}/publications/items"
    end
  end
end
