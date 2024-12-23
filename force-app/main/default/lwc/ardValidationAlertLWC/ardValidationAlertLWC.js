/* 
 * Created By  : Satyendra Vishwkarma
 * Last Modified By : Satyendra Vishwkarma
 * Description : For Ticket HRP-6051, It shows the alert notification to DRD & APS Profiles
 */
import { LightningElement,api,wire, track } from 'lwc';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import LightningConfirm from 'lightning/confirm';
import { updateRecord } from 'lightning/uiRecordApi';

export default class ArdValidationAlertLWC extends LightningElement {

    subscription = null;
    channelName = '/event/Opportunity_Event__e';
    @api recordId;
    // Fields passed from platform event
    changedFields = [];
    showDialog = false;
    isUserClickCancelled = false;

    connectedCallback() {
        console.log('HRP-6051 connectedCallback ');
        this.subscribeToEvent();
        onError(error => {
            console.error('HRP-6051 Streaming error::', JSON.stringify(error));
        });
    }
    disconnectedCallback() {
        console.log('HRP-6051 disconnectedCallback ');
        this.unsubscribeFromEvent();
    }

    subscribeToEvent() {
        console.log('HRP-6051 subscribeToEvent ');
        subscribe(this.channelName, -1, event => {
            this.handlePlatformEvent(event);
        }).then(response => {
            this.subscription = response;
            console.log(' HRP-6051 subscription :', JSON.stringify(this.subscription));
        });
    }
    unsubscribeFromEvent() {
        console.log('HRP-6051 unsubscribeFromEvent ');
        if (this.subscription) {
            unsubscribe(this.subscription, response => {
                console.log('HRP-6051 Unsubscribed from:', this.channelName);
            });
        }
    }
    handlePlatformEvent(event) {
        //console.log('HRP-6051 handlePlatformEvent :  ',event);
        console.log('HRP-6051 handlePlatformEvent :  ',JSON.stringify(event));
        const eventData = event.data.payload;
        if (eventData.RecordId__c === this.recordId) {
            // Parse Changed_Fields__c
            let rawChangedFields = eventData.Changed_Fields__c;
            console.log('HRP-6051 Raw Changed_Fields__c:', rawChangedFields);

            this.changedFields = Object.entries(JSON.parse(rawChangedFields)).map(([key, value]) => ({
                key,
                //label: key.replace(/_/g, ' '), // Replace underscores for better display
                value
            }));

            console.log('HRP-6051 Changed Fields:', JSON.stringify(this.changedFields));
            this.showPopup(eventData.Message__c);
        }
    }
    async showPopup(message) {
        const confirmation = await LightningConfirm.open({
            message: 'A change in procedure requires consideration to an updated Anticipated Registered Donors value that impacts resource and appointment slot allocation. Please update value as applicable. Do you want to proceed?',
            label: 'Warning',
            theme: 'warning' // Ensures the dialog box is styled as a warning
        });
        if (confirmation) {
            console.log('HRP-6051 User confirmed, proceeding to save');
            //this.isUserClickCancelled=false;
            this.rollbackChanges();
        }else{
            console.log('HRP-6051 User canceled, rolling back changes');
            //this.isUserClickCancelled=true;
            this.rollbackChanges();
        }
    }
    async rollbackChanges() {
        console.log('HRP-6051 Rolling back changes...isUserClickCancelled :',this.isUserClickCancelled);
        const fields = { 
            Id: this.recordId, 
            Pending_ARD_Confirmation__c: false
        };
        const recordInput = { fields };
        console.log('HRP-6051 recordInput ->',JSON.stringify(recordInput));
        try {
            await updateRecord(recordInput);
            console.log('HRP-6051 Rollback successful');
        } catch (error) {
            console.error('HRP-6051 Rollback failed:', JSON.stringify(error));
        } finally {
            console.error('HRP-6051 Rollback Finally block:');
        }
    }
    // async rollbackChanges() {
    //     console.log('HRP-6051 Rolling back changes...isUserClickCancelled :',this.isUserClickCancelled);
    //     const fields = { 
    //         Id: this.recordId, 
    //         Pending_ARD_Confirmation__c: false
    //     };
    //     if(this.isUserClickCancelled){
    //         // Set old values for each changed field
    //         this.changedFields.forEach(field => {
    //             fields[field.key] = field.value; // Rollback logic: Adjust based on requirements
    //         });
    //     }
         
    //     const recordInput = { fields };
    //     console.log('HRP-6051 recordInput ->',JSON.stringify(recordInput));
    //     try {
    //         await updateRecord(recordInput);
    //         console.log('HRP-6051 Rollback successful');
    //     } catch (error) {
    //         console.error('HRP-6051 Rollback failed:', JSON.stringify(error));
    //     } finally {
    //         console.error('HRP-6051 Rollback Finally block:');
    //     }
    // }
}