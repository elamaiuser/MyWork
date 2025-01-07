import { LightningElement, api, wire, track} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getHighlightAndFeedBacks from '@salesforce/apex/TaskService.getHighlightAndFeedBacks';
import updateHighlightAndFeedBacks from '@salesforce/apex/TaskService.updateHighlightAndFeedBacks';
export default class TaskHighlightsAndFeedback extends LightningElement {
    @api recordId;
    @track isVisible = true;
    @track highlights = '';
    @track serviceIssue = '';
    activeSection=['A'];

    @wire(getHighlightAndFeedBacks, { taskId: '$recordId' })
    wiredTask({ error, data }) {
        if (data) {
            console.error('TaskHighlightsAndFeedback details:', data);
            this.isVisible = data.isVisible;
            this.highlights = data.highlights;
            this.serviceIssue = data.serviceIssue;
        } else if (error) {
            console.error('Error fetching Task details:', error);
        }
    }

    handleUpdate() {
        let updateStatus = {};
        updateHighlightAndFeedBacks({taskId: this.recordId, highlights: this.highlights, serviceIssue: this.serviceIssue})
            .then(result => {
                updateStatus = result;
                console.log(updateStatus);
            })
            .catch(error => {
                console.log(error);
            })
            .finally(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: updateStatus.title,
                        message: updateStatus.message,
                        variant: updateStatus.variant
                    })
                );
            });
    }
}