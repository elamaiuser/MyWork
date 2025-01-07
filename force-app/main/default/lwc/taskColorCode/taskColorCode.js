import { LightningElement, wire, api, track} from 'lwc';
import getTaskColor from '@salesforce/apex/TaskService.getTaskColor';

export default class TaskColorCode extends LightningElement {
    @api recordId; 
    @track hasContent = false;
    colorContent = '';
    
    @wire(getTaskColor, { taskId: '$recordId' })
    wiredTask({ error, data }) {
        if (data) {
            this.colorContent = data;
            console.error('color code details:', this.colorContent);
            if (this.colorContent) {
                this.hasContent = true;
            }
            console.error('hasContent:', this.hasContent);
        } else if (error) {
            console.error('Error fetching order details:', error);
        }
    }
}