# frozen_string_literal: true

# Valkyrie::Storage::Fedora expects io objects to have #length
class ::File
  alias length size unless ::File.respond_to? :length
end
