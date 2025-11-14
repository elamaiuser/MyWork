import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { fireEvent } from 'c/pubsub';

export default class SlwcShiftJobs extends LightningElement {
    @api isReadonly;
    @api drive;
    @api masterData;
    @api isCreatable = false;
    @api isEditable = false;
    @api isDeletable = false;

    @api resourceType;
    @api shift;
    @api jobs;

    @wire(CurrentPageReference) pageRef;

    get buttonEnabled() {
        return !this.isReadonly && (this.resourceType == 'Person' || this.resourceType == 'Volunteer');
    }

    get showDualRoleAssignmentButton() {
        return !this.isReadonly && this.resourceType == 'Person' 
    }

    handleNewJob() {
        let eventValues = {action : "create", resourceType: this.resourceType, driveShift: this.shift, drive: this.drive };
        fireEvent(this.pageRef, 'showJobModal', eventValues);
    }

    handleDualRoleAssigment() {
        let eventValues = {resourceType: this.resourceType, driveShift: this.shift, drive: this.drive };
        fireEvent(this.pageRef, 'showDualRoleAssignmentModal', eventValues);
    }
}