import { LightningElement, track} from 'lwc';
import search from '@salesforce/apex/sponsorPlanningReportController.search';
export default class SponsorPlanningReport extends LightningElement {
    @track wrapper = {};
    selectedIds = '';
    columns = [
        {label: 'Account Name', fieldName: 'AccountURL', type: 'url', typeAttributes: {label: {fieldName: 'Name'}}},
        {label: 'Drive Name', fieldName: 'DriveURL', type: 'url', typeAttributes: {label: {fieldName: 'Drive_Name__c'}}},
        { label: 'Additional Description', fieldName: 'Additional_Description__c'},
        { label: 'Drive Date(s)', fieldName: 'Drive_Date__c', type:'date', typeAttributes: { day: "numeric", month: "numeric", year: "numeric" }},
        { label: 'Start Time', fieldName: 'Start_Time__c', type:'date', typeAttributes: { hour: '2-digit', minute: '2-digit', hour12: true }},
        { label: 'End Time', fieldName: 'End_Time__c', type:'date', typeAttributes: { hour: '2-digit', minute: '2-digit', hour12: true }},
        { label: 'WB Projected Procedures', fieldName: 'WB_Projected_Procedures__c' },
        { label: 'Web Schedule Start Date', fieldName: 'Web_Schedule_Start_Date__c', type:'date', typeAttributes: { day: "numeric", month: "numeric", year: "numeric", hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: true } },
        { label: 'Web Schedule End Date', fieldName: 'Web_Schedule_End_Date__c', type:'date' , typeAttributes: { day: "numeric", month: "numeric", year: "numeric", hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: true }},
        { label: 'Additional Drive Planning Notes', fieldName: 'Additional_Drive_Logistics__c' },
        { label: 'Call List Recipient ?', fieldName: 'Call_List_Recipient_Exist__c' },
        { label: 'Online Donor Message', fieldName: 'Online_Donor_Message__c' },
        { label: 'Publish to Call Center', fieldName: 'Publish_to_Call_Center__c' },
        { label: 'Send Emails', fieldName: 'Send_Emails__c' },
        { label: 'Send Mailers', fieldName: 'Send_Mailers__c' },
        { label: 'Online Scheduling Enabled', fieldName: 'Online_Scheduling_Enabled__c' },
    ];
    hasRecords = false;
    data = [];

    connectedCallback () {
        this.initializeWrapper();
    }
    
    handleSelectionPortfolio (event) {
        this.wrapper.portfolio = event.detail;
    }

    handleSelectionDriveTeamMember (event) {
        this.wrapper.driveTeamMember = event.detail;
    }

    handleChange (event) {
        this.wrapper[event.target.dataset.id] = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
    }

    handleClick (event) {
        if (event.target.name === 'search') {
            this.search();
        }
        if (event.target.name === 'export') {
            this.exportToPdf();
        }
        if (event.target.name === 'clear') {
            this.initializeWrapper();
        }
    }

    initializeWrapper () {
        this.wrapper = {
            'portfolio': '',
            'driveTeamMember': '',
            'startDate' : this.getStartDate(),
            'endDate' : this.getEndDate(),
            'account' : '',
            'withNotes' : false
        };
        this.selectedIds = '';
        this.hasRecords = false;
        this.data = [];
        const players = this.template.querySelectorAll('c-custom-lookup');
        if (players !== null && players.length > 0) {
            for(let i=0; i<players.length; i++){
                players[i].handleRemovePill();
            }
        }
    }

    exportToPdf () {
        if (this.selectedIds) {
            window.open('/apex/generatePdfWithData?ids='+this.selectedIds);
        }
    }

    search () {
        const start = this.wrapper.startDate ? this.wrapper.startDate : this.getStartDate ();        
        const end = this.wrapper.endDate ? this.wrapper.endDate : this.getEndDate ();        
        search({searchAcc : this.wrapper.account, searchPortfolio: this.wrapper.portfolio,searchStartDate: start, searchEndDate: end, searchTeamMember: this.wrapper.driveTeamMember})
            .then(result => {
                console.log('result:-'+result);
                if (result && result.length > 0) {
                    this.hasRecords = true;
                    this.data = result;
                    if(this.data){
                        this.data.forEach(item => item['AccountURL'] = '/lightning/r/Account/' +item['AccountId'] +'/view');
                        this.data.forEach(item => item['DriveURL'] = '/lightning/r/Opportunity/' +item['Id'] +'/view');
                    }
                }
            })
            .catch(error => {
                console.log(error);
            });
    }

    getSelectedIds (event) {
        let selectedIds = '';
        const selectedRows = event.detail.selectedRows;
        for (let i = 0; i < selectedRows.length; i++) {
            selectedIds += selectedRows[i].Id+'/';
        }
        this.selectedIds = selectedIds;
        console.log(this.selectedIds);
    }

    getStartDate () {
        let startDate = new Date();
        return startDate.toISOString().slice(0, 10);
    }

    getEndDate () {
        let endDate = new Date();
        endDate.setDate(endDate.getDate() + 98);
        return endDate.toISOString().slice(0, 10);
    }
}