import SaveManager from 'curation_concerns/file_manager/save_manager'
import SortManager from 'curation_concerns/file_manager/sorting'
import {FileManagerMember} from 'curation_concerns/file_manager/member'
export default class FileManager {
  constructor() {
    this.save_manager = this.initialize_save_manager()
    this.sorting()
    this.save_affix()
    this.member_tracking()
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
}
