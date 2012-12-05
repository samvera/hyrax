require 'rails/generators'

class TestAppGenerator < Rails::Generators::Base
  source_root File.expand_path("../../../../support", __FILE__)

  def run_blacklight_generator
    say_status("warning", "GENERATING BL", :yellow)       

    generate 'blacklight', '--devise'
  end

  def run_hydra_head_generator
    say_status("warning", "GENERATING HH", :yellow)       

    generate 'hydra:head', '-f'
  end

  def run_hydra_head_generator
    say_status("warning", "GENERATING HH", :yellow)       

  end

  def install_redis_config
    copy_file "config/redis.yml"
  end

  def run_sufia_generator
    say_status("warning", "GENERATING SUFIA", :yellow)       

    generate 'sufia', '-f'

    remove_file 'spec/factories/users.rb'
  end

  def remove_index_page
    remove_file 'public/index.html'
  end
  
  def install_fedora_conf
    copy_file 'fedora_conf/fedora.fcfg', '../../jetty/fedora/test/server/config/fedora.fcfg'
    copy_file 'fedora_conf/fedora.fcfg', '../../jetty/fedora/default/server/config/fedora.fcfg'
  end

end
