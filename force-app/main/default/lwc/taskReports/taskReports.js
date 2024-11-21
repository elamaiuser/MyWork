import { LightningElement, api, wire, track} from 'lwc';
import getReportLinks from '@salesforce/apex/TaskService.getReportLinks';

export default class TaskReports extends LightningElement {
    @api recordId; 
    @track hasReport = false;
    activeSection=['A'];
    reportData = [];
    
    @wire(getReportLinks, { taskId: '$recordId' })
    wiredOrder({ error, data }) {
        if (data) {
            this.reportData = data;
            console.error('reportData details:', this.reportData.length);
            if(this.reportData.length > 0){
                this.hasReport = true;
            }
        } else if (error) {
            console.error('Error fetching order details:', error);
        }
    }
}