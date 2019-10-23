# The default virus scanner Hyrax::Works, ported from hydra_works.
# If ClamAV is present, it will be used to check for the presence of a virus. If ClamAV is not
# installed or otherwise not available to your application, Hyrax::Works does no virus checking
# add assumes files have no viruses.
#
# To use a virus checker other than ClamAV:
#   class MyScanner < Hyrax::Works::VirusScanner
#     def infected?
#       my_result = Scanner.check_for_viruses(file)
#       [return true or false]
#     end
#   end
#
# Then set Hyrax::Works to use your scanner either in a config file or initializer:
#   Hyrax::Works.default_system_virus_scanner = MyScanner
module Hyrax
  class VirusScanner < Hydra::Works::VirusScanner
    private

      def warning(msg)
        Hyrax.logger&.warn(msg)
      end
  end
end
