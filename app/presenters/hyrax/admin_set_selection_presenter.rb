# frozen_string_literal: true
module Hyrax
  ##
  # @api public
  #
  # Presents select options for admin sets.
  #
  # @note this supersedes the older +Hyrax::AdminSetOptionsPresenter+, which
  #   actied more like a "service" sending database queries to Solr and
  #   ActiveRecord.  this version seeks only to present the input data and
  #   relies on its caller to pass in the right data.
  #
  # @since 3.1.0
  class AdminSetSelectionPresenter
    ##
    # @param [Array<#id>]
    def initialize(admin_sets:, ability:)
      @admin_sets = admin_sets
      @current_ability = ability
    end

    ##
    # @return [Array<Array<String, String, Hash>>] an array suitable for  a form
    #   input `collection:` parameter. it should contain a label, an id, and a
    #   hash of HTML5  data attributes.
    def select_options
      @admin_sets.map do |admin_set|
        case admin_set
        when OptionsEntry
          admin_set.result
        else
          OptionsEntry.new(admin_set: admin_set).result
        end
      end
    end

    class OptionsEntry
      ##
      # @!attribute [rw] admin_set
      #   @return [AdministrativeSet, SolrDocument]
      attr_accessor :admin_set

      ##.
      # @param [AdministrativeSet, SolrDocument] admin_set
      def initialize(admin_set:)
        @admin_set = admin_set
      end

      ##
      # @return [Array<String, String, Hash>]
      def result
        [label, id, data]
      end

      ##
      # @return [String]
      def label
        Array(admin_set.title).first || admin_set.to_s
      end

      ##
      # @return [String]
      def id
        admin_set.id.to_s
      end

      ##
      # @return [Hash{}]
      def data
        return {} unless admin_set.permission_template
        return PermissionTemplateData.new(
          permission_template: admin_set.permission_template,
          current_ability: @current_ability).attributes
      end
    end

    class PermissionTemplateData
      def initialize(permission_template:, current_ability:)
        @permission_template = permission_template
        @current_ability = current_ability
      end
      # all PermissionTemplate release & visibility data attributes (if not blank or false)
        def attributes
        {}.tap do |attrs|
          attrs['data-sharing'] = sharing?(permission_template: permission_template)
          # Either add "no-delay" (if immediate release) or a specific release date, but not both.
          if permission_template.release_no_delay?
            attrs['data-release-no-delay'] = true
          elsif permission_template.release_date.present?
            attrs['data-release-date'] = permission_template.release_date
          end
          attrs['data-release-before-date'] = true if permission_template.release_before_date?
          attrs['data-visibility'] = permission_template.visibility if permission_template.visibility.present?
        end
      end

      # Does the workflow for the currently selected permission template allow sharing?
      def sharing?(permission_template:)
        # This short-circuit builds on a stated "promise" in the UI of
        # editing an admin set:
        #
        # > Managers of this administrative set can edit the set
        # > metadata, participants, and release and visibility
        # > settings. Managers can also edit work metadata, add to or
        # > remove files from a work, and add new works to the set.
        return true if @current_ability.can?(:manage, permission_template)

        # Otherwise, we check if the workflow was setup, active, and
        # allows_access_grants.
        wf = workflow(permission_template: permission_template)
        return false unless wf
        wf.allows_access_grant?
      end

      def workflow(permission_template:)
        return unless permission_template.active_workflow
        Sipity::Workflow.find_by!(id: permission_template.active_workflow.id)
      end
    end

  end
end
