import ThumbnailSelect from 'hyrax/thumbnail_select'
import Participants from 'hyrax/admin/admin_set/participants'
import tabifyForm from 'hyrax/tabbed_form'

// Controls the behavior of the Collections edit form
// Add search for thumbnail to the edit descriptions
export default class {
  constructor(elem) {
    let url =  window.location.pathname.replace('edit', 'files')
    let field = elem.find('#collection_thumbnail_id')
    this.thumbnailSelect = new ThumbnailSelect(url, field)
    tabifyForm(elem.find('form.editor'))

    let participants = new Participants(elem.find('#participants'))
    participants.setup()
  }
}
