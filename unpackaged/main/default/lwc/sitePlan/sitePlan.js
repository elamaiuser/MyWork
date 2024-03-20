import { LightningElement , api , wire} from 'lwc';
import getOpportunityList from '@salesforce/apex/SitePlanForTemplatesHelper.SitePlanForTemplatesHelper';

import { publish, MessageContext } from 'lightning/messageService';
import recordSelected from '@salesforce/messageChannel/Record_Selected__c';

const columns = [
    { label: 'Template Name', fieldName: 'Name' },
    { label: 'Account Name', fieldName: 'accountName', type: 'text' },
];

export default class SitePlan extends LightningElement {
    @api recordId;
    columns = columns;
    error;
    opps;
    oppRecord;
    isNullTemplates;

    connectedCallback()
    {
        if(this.recordId)
        {
            getOpportunityList({recordId:this.recordId})
            .then(
                result => {
                    let preparedArr = [];
                    if(result.length > 0)
                    {
                        
                        result.forEach(record => {
                            let preparedRec = {};
                            preparedRec.Id = record.Id;
                            preparedRec.Name = record.Name;
                            preparedRec.accountName = record.Account.Name;
                            preparedArr.push(preparedRec);
                        
                    });
                    this.opps = preparedArr;
                    this.isNullTemplates = true;
                    console.log('Opportunities: '+JSON.stringify(this.opps));
                }}
            ).catch(
                error => {
                    console.log('Error is :'+JSON.stringify(error));
                }
            )
        }
    }

    @wire(MessageContext)
    messageContext;

    handleRowSelection = event => {
        var selectedRows=event.detail.selectedRows;
        this.oppRecord = selectedRows[0].Id;
        //alert('Selected Id - '+this.oppRecord);

        const payload = { recordId: this.oppRecord};
        console.log('payload -'+JSON.stringify(payload));
        
        publish(this.messageContext, recordSelected, payload);

        
    }
}