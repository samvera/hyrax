import SaveManager from 'curation_concerns/file_manager/save_manager'
import SortManager from 'curation_concerns/file_manager/sorting'
import {FileManagerMember} from 'curation_concerns/file_manager/member'
export default class FileManager {
  constructor() {
    this.save_manager = this.initialize_save_manager()
    this.sorting()
    this.save_affix()
    this.member_tracking()
    this.sortable_placeholder()
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
