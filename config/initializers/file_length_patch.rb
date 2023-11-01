# frozen_string_literal: true

# Valkyrie::Storage::Fedora expects io objects to have #length
class ::File
  alias length size unless respond_to? :length
end

class ::Valkyrie::StorageAdapter::StreamFile
  alias length size unless respond_to? :length
end
