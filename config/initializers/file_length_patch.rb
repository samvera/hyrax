# Valkyrie::Storage::Fedora expects io objects to have #length
class ::File
  alias_method :length, :size unless ::File.respond_to? :length
end