import { LightningElement, track, api } from 'lwc';
import {publish, subscribe, createMessageContext, releaseMessageContext } from "lightning/messageService";
import periodRefMC from '@salesforce/messageChannel/PeriodReferenceMessageChannel__c';
import generalReferenceMC from '@salesforce/messageChannel/GeneralReferenceMessageChannel__c';
import selectedDriveMC from '@salesforce/messageChannel/SelectedDriveMessageChannel__c';
import getDrives from '@salesforce/apex/DriveService.retrieveProspectDrives';

export default class ProspectDrives extends LightningElement {
    context = createMessageContext();

    subscription = null;
    receivedMsg;
    drives;
    showDrives = false;
    showSpinner = false;
    @api drivesToShow = 10;
    periodId;

    @track columns = [
        {
            label: 'Name',
            fieldName: 'driveName',
            type: 'text',
            wrapText : true
        },
        {
            label: 'Health',
            fieldName: 'drivehealth',
            type: 'text'
        },
        {
            label: 'Date',
            fieldName: 'driveDate',
            type: 'date-local',
            typeAttributes: {
                month:"2-digit",
                day:"2-digit"
            }
        },
        {
            label: 'Start',
            fieldName: 'startTime',
            type: 'date',
            typeAttributes: {
                hour:"2-digit",
                minute:"2-digit"
            }
        },
        {
            label: 'End',
            fieldName: 'endTime',
            type: 'date',
            typeAttributes: {
                hour:"2-digit",
                minute:"2-digit"
            }          
        },
        {
            label: 'Projected Procedures',
            fieldName: 'totalProjectedProcedures',
            type: 'number'
        }                                                 
    ];

    constructor() {
        super();

        this.subscription = subscribe(
            this.context,
            periodRefMC,
            message => {
                this.receivePeriodMessage(message);
            }
        );
        // get the current selected period if lazy loading  
        if (!this.periodId) {
            const message = {
                recordId: null,
                message : 'Query Period',
                source: 'driveCalendar.lwc',
                recordData : { queryType: 'PeriodReference'}    
            };

            publish (this.context, generalReferenceMC, message);  
        }          
    }

    receivePeriodMessage(message) {
        if (this.periodId != message.recordId) {
            this.showSpinner = true;
            this.periodId = message.recordId;
        
            getDrives({periodId: message.recordId, drivesToShow: this.drivesToShow})
            .then(theResponse => {
                if (theResponse.length) {
                    this.drives = theResponse;
                    this.showDrives = true;
                } else {
                    this.drives = null;
                    this.showDrives = false;
                }

                this.showSpinner = false;
            });
        }        
    }
    disconnectedCallback() {
        releaseMessageContext(this.context);
    }   
    sendSelectedDriveMessage(driveId, collectionOpId, collectionOpName) {
        const message = {
             recordId: driveId,
             message : 'Drive Selected',
             source: 'plannedDrives.lwc',
             recordData : { collectionOpId :  collectionOpId, collectionOpName : collectionOpName }    
        };

        publish (this.context, selectedDriveMC, message);
    }
    showOpportunity(event) {
        const selectedDrives = event.detail.selectedRows;

        if (selectedDrives.length) {
            this.sendSelectedDriveMessage( selectedDrives[0].driveId, 
                                           selectedDrives[0].collectionOpId,
                                           selectedDrives[0].collectionOpName);
        }
    }  
}