// The editor for the CollectionTypeParticipant
// Add search for user/group to the edit an admin set's participants page
import Participants from 'hyrax/admin/collection_type/participants'
import Settings from 'hyrax/admin/collection_type/settings'
import tabifyForm from 'hyrax/tabbed_form'

export default class {
    constructor(elem) {
        let participants = new Participants(elem.find('#participants'))
        participants.setup()
        let settings = new Settings(elem.find('#settings'))
        settings.setup()
        tabifyForm(elem.find('form.edit_collection_type'))
    }
}
