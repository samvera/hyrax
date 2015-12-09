require 'curation_concerns'

# Pull in jetty-related tasks from CurationConcerns rather than duplicate them
spec = Gem::Specification.find_by_name 'curation_concerns'
load "#{spec.gem_dir}/tasks/jetty.rake"

spec = Gem::Specification.find_by_name 'curation_concerns-models'
load "#{spec.gem_dir}/lib/tasks/curation_concerns-models_tasks.rake"
