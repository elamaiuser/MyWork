import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { fireEvent } from 'c/pubsub';
import {
    DateTime
} from 'c/luxon';
import { find, cloneDeep } from 'c/lodash';
import * as slwcUtils from 'c/slwcUtils';
import TIME_ZONE from '@salesforce/i18n/timeZone';
import { DRIVE_DELIVERY_JOB_DISPLAY_MODE } from 'c/slwcConstants';
import slwcDriveDeliveryJobTableTemplate from './slwcDriveDeliveryJobTable.html';
import slwcDriveDeliveryJobWidgetTemplate from './slwcDriveDeliveryJobWidget.html';

const ACTIONS = [
    { label: 'Edit', name: 'edit'}, 
    { label: 'Delete', name: 'delete'}
];

export default class SlwcDriveDeliveryJobTable extends LightningElement {
    @api drive;
    @api isReadonly;
    @api displayMode = DRIVE_DELIVERY_JOB_DISPLAY_MODE.TAB;
    
    @api 
    set driveDeliveryJobs(input) {
        if (input) {
            this.driveDriveDeliveryList = (input || []).map(item => {
                return {
                    ...item,
                    recordPageUrl: '/' + item.id
                }
            })
        }
    }
    get driveDeliveryJobs() {
        return this.driveDriveDeliveryList;
    }
    
    @track driveDriveDeliveryList = [];
   
    get timezoneSidId() {
        let timezoneSidId = TIME_ZONE;
        if (this.drive && this.drive.driveSite && this.drive.driveSite.timezoneSidId) {
            timezoneSidId = this.drive.driveSite.timezoneSidId;
        }
        return timezoneSidId;
    }

    get columns() {
        let timezoneSidId = this.timezoneSidId;
        let columns = [];
        // columns.push({ label: 'Delivery Id', fieldName: 'deliveryId', type: 'text' });
        columns.push({ label: 'Vehicle', fieldName: 'vehicle', type: 'text' });
        columns.push({ label: 'Type', fieldName: 'type', type: 'text' });
        columns.push({ label: 'Start', fieldName: 'start', type: 'date', typeAttributes: {
            year: 'numeric',
            month: 'numeric',
            day: 'numeric',
            hour: 'numeric',
            minute: '2-digit',
            timeZone: timezoneSidId
        }, hideDefaultActions: true });
        columns.push({ label: 'End', fieldName: 'end', type: 'date', typeAttributes: {
            year: 'numeric',
            month: 'numeric',
            day: 'numeric',
            hour: 'numeric',
            minute: '2-digit',
            timeZone: timezoneSidId
        }, hideDefaultActions: true });
        columns.push({ label: 'Pick Up', fieldName: 'pickUp', type: 'date', typeAttributes: {
            year: 'numeric',
            month: 'numeric',
            day: 'numeric',
            hour: 'numeric',
            minute: '2-digit',
            timeZone: timezoneSidId
        }, hideDefaultActions: true });
        columns.push({ label: 'Arrive', fieldName: 'arrive', type: 'date', typeAttributes: {
            year: 'numeric',
            month: 'numeric',
            day: 'numeric',
            hour: 'numeric',
            minute: '2-digit',
            timeZone: timezoneSidId
        }, hideDefaultActions: true });
        columns.push({ label: 'Drive Bag', fieldName: 'driveBags',  type: 'driveBag', typeAttributes: ['showDriveBag']});
        
        if (!this.isReadonly) {
            columns.push({ type: 'action',fieldName: 'id', typeAttributes: { rowActions: ACTIONS, clickAction: (event) => this.clickAction(event) } });
        }
        return columns;
    }
    
    get isMobile() {
        return slwcUtils.isMobile()
    }

    @wire(CurrentPageReference) pageRef;
    
    render() {
        if(this.displayMode === DRIVE_DELIVERY_JOB_DISPLAY_MODE.TAB){
            return slwcDriveDeliveryJobTableTemplate;
        } if(this.displayMode === DRIVE_DELIVERY_JOB_DISPLAY_MODE.WIDGET) { 
            return slwcDriveDeliveryJobWidgetTemplate;
        }
    }

    clickAction(event){
        const actionName = event.currentTarget.name
        const id = event.currentTarget.dataset.value
        const row = find(this.driveDriveDeliveryList,(item) => item.id === id)
        switch (actionName) {
            case 'edit':
                this.editDriveDeliveryJob(row);
                break;
            case 'delete':
                this.deleteDriveDeliveryJob(row);
                break;
        }
    }

    formatTime(time) {
        if(!time){
            return ""
        }
        return DateTime.fromFormat(time, 'HH:mm:ss.SSS').toFormat('h:mm a');
    }
    editDriveDeliveryJob(driveDeliveryJobs) {
        let eventValues = {action: "edit", driveDeliveryJobs: driveDeliveryJobs};
        fireEvent(this.pageRef, 'showDriveDeliveryJobModal', eventValues);
    }

    deleteDriveDeliveryJob(driveDeliveryJobs) {
        let eventValues = {action: "delete", driveDeliveryJobs: driveDeliveryJobs};
        fireEvent(this.pageRef, 'showDriveDeliveryJobModal', eventValues);
    }

    handleRowActions(event) {
        let actionName = event.detail.action.name;
        let row = event.detail.row;

        switch (actionName) {
            case 'edit':
                this.editDriveDeliveryJob(row);
                break;
            case 'delete':
                this.deleteDriveDeliveryJob(row);
                break;
        }
    }
    
    handleWidgetActions(event) {
        let actionName = event.currentTarget.dataset['action'];
        let recordId = event.currentTarget.dataset['value'];
        let row = this.driveDriveDeliveryList.find(item => item.id === recordId);

        switch (actionName) {
            case 'edit':
                this.editDriveDeliveryJob(row);
                break;
            case 'delete':
                this.deleteDriveDeliveryJob(row);
                break;
        }
    }
}