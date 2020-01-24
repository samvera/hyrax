import ThumbnailSelect from 'hyrax/thumbnail_select'
import Participants from 'hyrax/admin/admin_set/participants'
import tabifyForm from 'hyrax/tabbed_form'

// Controls the behavior of the Collections edit form
// Add search for thumbnail to the edit descriptions
// this method used to simply replace the string edit
// but now replaces the last url part if and only if
// that part is edit
export default class {
  constructor(elem) {
    let field = elem.find('#collection_thumbnail_id')
    this.thumbnailSelect = new ThumbnailSelect(this.url(), field)
    tabifyForm(elem.find('form.editor'))

    let participants = new Participants(elem.find('#participants'))
    participants.setup()
  }

  url() {
    let urlParts = window.location.pathname.split("/")
    if(urlParts[urlParts.length - 1] === "edit") {
      urlParts[urlParts.length - 1] = "files"
    }
    return urlParts.join("/") 
  }
}
