import { LightningElement, track, api } from 'lwc';
import {publish, subscribe, createMessageContext, releaseMessageContext } from "lightning/messageService";
import periodRefMC from '@salesforce/messageChannel/PeriodReferenceMessageChannel__c';
import selectedDriveMC from '@salesforce/messageChannel/SelectedDriveMessageChannel__c';
import getDrives from '@salesforce/apex/DriveService.retrieveDrives';
import generalReferenceMC from '@salesforce/messageChannel/GeneralReferenceMessageChannel__c';

export default class PlannedDrives extends LightningElement {
    context = createMessageContext();

    subscription = null;
    generalReferenceSubscription = null;
    receivedMsg;
    drives;
    showDrives = false;
    showSpinner = false;
    @api drivesToShow = 10;
    periodId;
    driveId;
    collectionOpId;
    collectionOpName; 

    @track columns = [
        {
            label: 'Name',
            fieldName: 'driveName',
            type: 'text',
            wrapText : true
        },
        {
            label: 'Stage',
            fieldName: 'stageName',
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


        this.generalReferenceSubscription = subscribe(
            this.context,
            generalReferenceMC,
            message => {
                this.receiveQueryMessage( message );
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

    receiveQueryMessage ( message ) {
        console.log('Got message... queryType:' + message.recordData.queryType);
        
        if (message.recordData.queryType === 'CollectionOperationReference') {
            this.sendSelectedDriveMessage( this.driveId, 
                this.collectionOpId,
                this.collectionOpName);
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
        this.driveId = event.detail.selectedRows[0].driveId;
        this.collectionOpId = event.detail.selectedRows[0].collectionOpId;
        this.collectionOpName = event.detail.selectedRows[0].collectionOpName;

        this.sendSelectedDriveMessage( this.driveId, 
                                       this.collectionOpId,
                                       this.collectionOpName);
    } 
}