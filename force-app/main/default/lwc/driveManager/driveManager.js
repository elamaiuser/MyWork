import { LightningElement, track, api } from 'lwc';
import {subscribe, createMessageContext, releaseMessageContext } from "lightning/messageService";
import selectedDriveMC from '@salesforce/messageChannel/SelectedDriveMessageChannel__c';
import getDrive from '@salesforce/apex/DriveService.retrieveDrive';
import { NavigationMixin } from 'lightning/navigation';

export default class DriveManager extends NavigationMixin(LightningElement) {
    context = createMessageContext();

    subscription = null;
    @api driveId;
    @api steps;
    showSpinner = false;
    @api driveName;
    @api stageName;
    @api showDrive = false;
    @api calendarDriveId = null;
    showCalendarDriveButton = false;

    constructor() {
        super();

        this.subscription = subscribe(
            this.context,
            selectedDriveMC,
            message => {
                this.receiveSelectedDriveMessage(message);
            }
        );
    }

    receiveSelectedDriveMessage(message) {
        this.showSpinnger = true;

        getDrive({driveId: message.recordId})
        .then(theResponse => {
            this.steps = theResponse.stages;
            this.driveName = 'Drive: ' + theResponse.driveName;
            this.stageName = theResponse.stageName;
            this.calendarDriveId = theResponse.calendarDriveId;

            if (this.calendarDriveId) {
                this.showCalendarDriveButton = true;
            } else {
                this.showCalendarDriveButton = false;
            }

            this.showSpinner = false;
            this.showDrive = true;
        });  

        this.driveId = message.recordId;
    }
    showOpportunity(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.driveId,
                actionName: 'view'
            }
        });
    }
    showCalendaredDrive(event) {
        console.log('In showDrive');
        console.log(this.calendarDriveId);
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.calendarDriveId,
                actionName: 'view'
            }
        });
    }    
}