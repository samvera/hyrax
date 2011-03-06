class JettyCleaner

  def self.clean(namespace=nil)
    objects = Fedora::Repository.instance.find_objects(:limit=>1000000)
    
    objects.each do |obj|
      case obj
      when ActiveFedora::Base
        puts "deleting #{obj.pid}"
      when Fedora::FedoraObject
        puts "found FedoraObject #{obj.pid}"
        if namespace
          if obj.pid.match(/^#{namespace}:/)
            puts "deleting #{obj.pid} from namespace #{namespace}" 
            ActiveFedora::Base.load_instance( obj.pid ).delete
          end
        else
          puts "deleting #{obj.pid}"
          ActiveFedora::Base.load_instance( obj.pid ).delete
        end
      else
        puts "#{obj.pid} is a #{obj.class}. Could not load and delete it."
      end
    end
    nil
  end
end
