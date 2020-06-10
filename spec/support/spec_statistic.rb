# frozen_string_literal: true
# This is a replacement for the OpenStruct usage. The idea is to expose
# an object with a common interface.
class SpecStatistic
  def initialize(**kargs)
    @attributes = kargs.symbolize_keys
  end

  def [](key)
    @attributes[key.to_sym]
  end

  def method_missing(method_name, *arguments, &block)
    if @attributes.key?(method_name.to_sym)
      @attributes[method_name]
    else
      super
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    @attributes.key?(method_name.to_sym) || super
  end
end
