module Sufia
  module InternalUris
    def id_to_uri(id)
      id = (id.scan(/..?/).first(4) + [id]).join('/')
      id = "#{FedoraLens.base_path}/#{id}" unless id.start_with? "#{FedoraLens.base_path}/"
      FedoraLens.host + id
    end

    def uri_to_id(uri)
      id = uri.to_s.sub(FedoraLens.host + FedoraLens.base_path, '')
      id.split('/')[-1]
    end
  end
end
