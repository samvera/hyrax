import SaveManager from 'hyrax/file_manager/save_manager'
import SortManager from 'hyrax/file_manager/sorting'
import {InputTracker, FileManagerMember} from 'hyrax/file_manager/member'
export default class FileManager {
  constructor() {
    this.save_manager = this.initialize_save_manager()
    this.sorting()
    this.save_affix()
    this.member_tracking()
    this.sortable_placeholder()
    this.resource_form()
  }

  initialize_save_manager() {
    return(new SaveManager)
  }

  sorting() {
    window.new_sort_manager = new SortManager(this.save_manager)
  }

  save_affix() {
    let tools = $("#file-manager-tools")
    if(tools.length > 0) {
      tools.affix({
        offset: {
          top: $("#file-manager-tools .actions").offset().top,
          bottom: function() {
            return $("#file-manager-extra-tools").outerHeight(true) + $("footer").outerHeight(true)
          }
        }
      })
    }
  }

  member_tracking() {
    let sm = this.save_manager
    $("li[data-reorder-id]").each(function(index, element) {
      var manager_member = new FileManagerMember($(element), sm)
      $(element).data("file_manager_member", manager_member)
    })
  }

  // Initialize a form that represents the parent resource as a whole.
  // For the purpose of CC, this comes with hidden fields for
  // thumbnail_id and representative_id
  // which are synchronized with the radio buttons on each member and then
  // submitted with the SaveManager.
  resource_form() {
    let manager = new FileManagerMember($("#resource-form").parent(), this.save_manager)
    $("#resource-form").parent().data("file_manager_member", manager)
    // Track thumbnail ID hidden field
    new InputTracker($("*[data-member-link=thumbnail_id]"), manager)
    $("#sortable *[name=thumbnail_id]").on("change", function() {
      let val = $("#sortable *[name=thumbnail_id]:checked").val()
      $("*[data-member-link=thumbnail_id]").val(val)
      $("*[data-member-link=thumbnail_id]").change()
    })
    new InputTracker($("*[data-member-link=representative_id]"), manager)
    $("#sortable *[name=representative_id]").on("change", function() {
      let val = $("#sortable *[name=representative_id]:checked").val()
      $("*[data-member-link=representative_id]").val(val)
      $("*[data-member-link=representative_id]").change()
    })
  }

  // Keep the ui/sortable placeholder the right size.
  // This keeps the grid a consistent height so when the
  // last row contains 1 object,
  // - an element can be moved into the last spot, and
  // - the footer doesn't jump up.
  sortable_placeholder() {
    $( "#sortable" ).on( "sortstart", function( event, ui ) {
      let found_element = $("#sortable").children("li[data-reorder-id]").first()
      ui.placeholder.width(found_element.width())
      ui.placeholder.height(found_element.height())
    })
  }
}
