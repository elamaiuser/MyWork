import { LightningElement,wire,track } from 'lwc';
import fetchopportunities from '@salesforce/apex/FetchOpportunityList.listOppLwc';
import { getPicklistValues} from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import Opp_Stage from '@salesforce/schema/Opportunity.StageName';
import OPPORTUNITY_OBJECT from '@salesforce/schema/Opportunity';
import updateOppLwc from '@salesforce/apex/FetchOpportunityList.updateOppLwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'

const columns = [
    { label: 'Name', fieldName: 'Name'},
    { label: 'Account', fieldName: 'AccountName'},
    { label: 'Drive Date',fieldName: 'Drive_Date__c', type: 'date'},
    { label: 'Description', fieldName: 'Description'}
];
 
export default class MassUpdateOpp extends LightningElement {
    @track columns = columns;
    @track data = [];
    @track pickListvalues;
    @track error;
    @track value;
    @track pickListvaluesByRecordType;
    @track opportunityStage;
    dataLoaded = false;
    
    renderedCallback()
    {
        console.log('template is rendered'+ this.dataLoaded);
    }

    @wire(fetchopportunities) 
    opp({error,data}) {
        if (data) {
            let currentData = [];
            let recordIds = [];
            data.forEach((row) => {
                let rowData = {};
                rowData.Id  = row.Id;
                rowData.Name = row.Name;
                rowData.Drive_Date__c = row.Drive_Date__c;
                rowData.Description = row.Description;
                if (row.Account) {
                    rowData.AccountName = row.Account.Name;
                }
                currentData.push(rowData);
                recordIds.push(row.Id);
            });
            this.data = currentData;
            this.dataLoaded = true;
        } else if (error) {
            this.error = error;
        }
    }

    @wire(getObjectInfo, { objectApiName: OPPORTUNITY_OBJECT })
    opportunityMetadata;

    @wire(getPicklistValues,
        {
            recordTypeId: '$opportunityMetadata.data.defaultRecordTypeId', 
            fieldApiName: Opp_Stage
        })
    stageNamePicklist;

    handleChange(event) {
        this.value = event.detail.value;
    }

    handleClick(){
        this.dataLoaded = false;
        if(this.value){
        let selectedRecords =  
        this.template.querySelector("lightning-datatable").getSelectedRows();  
            if(selectedRecords.length != 0){      
            for(let i=0; i<selectedRecords.length; i++){
            selectedRecords[i].Description = this.value;
            }
        updateOppLwc({oppListToUpdate:selectedRecords})
        .then(() => {
               this.dataLoaded = true;
               const event = new ShowToastEvent({
                title: 'Opportunity Updated',
                message: 'Updated Successfully!!!',
                variant: 'success'
            });
            this.dispatchEvent(event);
            this.value = '';
        })
        .catch(error => {
            console.log(error);
            this.error = error;
        });
        }
        else{
            alert('Please Select 1 Drive');
            this.dataLoaded = true;
        }   
        }
        else{
            alert('Please Select a Description');
            this.dataLoaded = true;
        }
    }
}