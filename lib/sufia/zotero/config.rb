 module Sufia
   module Zotero
     def self.config
       @config ||= reload_config!
     end

     def self.reload_config!
       @config = YAML.load(ERB.new(IO.read(File.join(Rails.root, 'config', 'zotero.yml'))).result)['zotero']
     end

     def self.publications_url(zotero_userid)
       "/users/#{zotero_userid}/publications/items"
     end
   end
 end
