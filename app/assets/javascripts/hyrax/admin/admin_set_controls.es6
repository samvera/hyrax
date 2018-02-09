// The editor for the AdminSets
// Add search for user/group to the edit an admin set's participants page
// Add search for thumbnail to the edit descriptions
import Visibility from 'hyrax/admin/admin_set/visibility'
import Participants from 'hyrax/admin/admin_set/participants'
import ThumbnailSelect from 'hyrax/thumbnail_select'
import tabifyForm from 'hyrax/tabbed_form'

export default class {
    constructor(elem) {
        let url = window.location.pathname.replace('edit', 'files')
        this.thumbnailSelect = new ThumbnailSelect(url, elem.find('#admin_set_thumbnail_id'))

        let participants = new Participants(elem.find('#participants'))
        participants.setup()

        let visibilityTab = new Visibility(elem.find('#visibility'))
        visibilityTab.setup()
        tabifyForm(elem.find('form.edit_admin_set'))
    }
}
