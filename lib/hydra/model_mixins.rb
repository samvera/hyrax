module Hydra::ModelMixins;end
Dir[File.join(File.dirname(__FILE__), "model_mixins", "*.rb")].each {|f| require f}
