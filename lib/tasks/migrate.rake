namespace :sufia do
  namespace :migrate do
    task move_all_works_to_admin_set: :environment do
      require 'sufia/move_all_works_to_admin_set'
      MoveAllWorksToAdminSet.run(AdminSet.find(AdminSet::DEFAULT_ID))
    end

    desc "Migrate workflow data from 7.3.0.rc1"
    task from_7_3_0rc1_release: :environment do
      logger = Logger.new(STDOUT)
      logger.level = Logger::DEBUG
      logger.info(%(Starting migration to Sufia 7.3.0 in preparation for Hyrax 1.0.0))
      Sipity::Workflow.transaction do
        logger.info(%(Migrating "complete" state to "deposited" state for all "one_step_mediated_deposit" workflows. See https://github.com/projecthydra/sufia/commit/711bb49892aa54fe190a45434f6b2d0364d69c7a for changes))
        Sipity::Workflow.where(name: 'one_step_mediated_deposit').each do |workflow|
          workflow.workflow_states.where(name: 'complete').each do |state|
            logger.info(%(Updating name for #{state.class} ID=#{state.id} from 'complete' to 'deposited'))
            state.update!(name: 'deposited')
          end
        end
      end

      logger.info(%(Completed migration to Sufia 7.3.0))
    end
  end
end
