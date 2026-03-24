import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { fireEvent } from 'c/pubsub';
import * as slwcUtils from 'c/slwcUtils';
import { ASSET_TYPE, RESOURCE_TYPE, DRIVE_TYPE, MANUALLY_CREATED_FROM } from 'c/slwcConstants';
import { find } from 'c/lodash';
import { DriveHelper } from 'c/slwcDriveGenerator';

export default class SlwcDriveShiftJobTable extends LightningElement {
    driveHelper = new DriveHelper()
    @wire(CurrentPageReference) pageRef;
    @api drive;
    @api masterData;
    @api isReadonly;
    @api isCreatable = false;
    @api isEditable = false;
    @api isDeletable = false;
    @api shift;
    @api jobs;
    @api resourceType;

    get isMobile() {
        return slwcUtils.isMobile()
    }
    get columns() {
        let columns = [];

        if (this.resourceType == RESOURCE_TYPE.PERSON) {
            columns.push({ label: 'Resource Role', fieldName: 'resourceRole', type: 'text', initialWidth: 160 });
            columns.push({ label: 'Dual Role', fieldName: 'dualRole', type: 'text', initialWidth: 140 });     
            columns.push({ label: 'Tag Names', fieldName: 'tagNames', type: 'text', initialWidth: 280, wrapText: true, cellAttributes: { alignment: 'left' } });
            columns.push({ label: 'Quantity', fieldName: 'quantity', type: 'jobQuantity', initialWidth: 110, cellAttributes: { alignment: 'left' }, typeAttributes: {
                showAPTQuantity: {fieldName: 'showAPTQuantity'},
                aptQuantity: {fieldName: 'aptQuantity'},
                vphhQuantity: {fieldName: 'vphhQuantity'},
                quantity: {fieldName: 'quantity'},
            }});
        }
        if (this.resourceType == RESOURCE_TYPE.VOLUNTEER) {
            columns.push({ label: 'Volunteer Role', fieldName: 'volunteerRole', type: 'text' });
            columns.push({ label: 'Tag Names', fieldName: 'tagNames', type: 'text', wrapText: true, cellAttributes: { alignment: 'left' } });
            columns.push({ label: 'Red Cross Volunteer Quantity', fieldName: 'redcrossVolunteerQuantity', type: 'number', cellAttributes: { alignment: 'left' } });
            columns.push({ label: 'Sponsor Volunteer Quantity', fieldName: 'sponsorVolunteerQuantity', type: 'number', cellAttributes: { alignment: 'left' } });
            if(
                this.driveHelper.isFixedSiteDrive(this.drive) ||
                this.driveHelper.isWbFixedSiteDrive(this.drive)
            ) {
                columns.push({ label: 'Locked', fieldName: 'isLocked', type: 'boolean' });
            }
        }
        if (this.resourceType == ASSET_TYPE.VEHICLE || this.resourceType == ASSET_TYPE.EQUIPMENT) {
            columns.push({ label: 'Asset Type', fieldName: 'assetType', type: 'text' });
            if (this.resourceType == ASSET_TYPE.EQUIPMENT) {
                columns.push({ label: 'Equipment Subtype', fieldName: 'equipmentSubtype', type: 'text' });
            }
            columns.push({ label: 'Tag Names', fieldName: 'tagNames', type: 'text', wrapText: true, cellAttributes: { alignment: 'left' } });
            columns.push({ label: 'Quantity', fieldName: 'quantity', type: 'number', cellAttributes: { alignment: 'left' } });
        }
        if (this.resourceType == RESOURCE_TYPE.PERSON) {
            columns.push({ label: 'Lead Time', fieldName: 'leadTime', type: 'number', initialWidth: 85, cellAttributes: { alignment: 'left' } });
            columns.push({ label: 'Travel Time', fieldName: 'travelTime', type: 'number', initialWidth: 95, cellAttributes: { alignment: 'left' } });
            columns.push({ label: 'Site Logistics To', fieldName: 'siteLogisticsTo', type: 'number', initialWidth: 130, cellAttributes: { alignment: 'left' } });
            columns.push({ label: 'Setup Time', fieldName: 'setupTime', type: 'number', initialWidth: 95, cellAttributes: { alignment: 'left' } });
            columns.push({ label: 'Breakdown Time', fieldName: 'breakdownTime', type: 'number', initialWidth: 125, cellAttributes: { alignment: 'left' } });
            columns.push({ label: 'Wrap-up Time', fieldName: 'wrapUpTime', type: 'number', initialWidth: 110, cellAttributes: { alignment: 'left' } });
            columns.push({ label: 'Travel Time', fieldName: 'travelTime2', type: 'number', initialWidth: 95, cellAttributes: { alignment: 'left' } });
            columns.push({ label: 'Site Logistics Back', fieldName: 'siteLogisticsBack', type: 'number', initialWidth: 130, cellAttributes: { alignment: 'left' } });
        }
        if (!this.isReadonly && (this.isEditable || this.isDeletable)) {
            let rowActions = [];
            if (this.isEditable) {
                rowActions.push({ label: 'Edit', name: 'edit'});

                if(
                    this.resourceType == RESOURCE_TYPE.VOLUNTEER && (
                        this.driveHelper.isFixedSiteDrive(this.drive) ||
                        this.driveHelper.isWbFixedSiteDrive(this.drive)
                    )
                ) {
                    if (
                        this.driveHelper.isAPSUser(this.masterData.loginUser) || 
                        this.driveHelper.isTelerecuiterUser(this.masterData.loginUser)
                    ) {
                        rowActions.push({ label: 'Bulk Edit', name: 'bulk-edit-volunteer-jobs'});
                        rowActions.push({ label: 'Bulk Add', name: 'bulk-add-volunteer-jobs'});
                    }
                }
            }
            if (this.isDeletable) {
                rowActions.push({ label: 'Delete', name: 'delete'});
            }
            columns.push({ type: 'action', fieldName: 'key', typeAttributes: { rowActions: rowActions, clickAction: (event) => this.clickAction(event)} });
        }
        return columns;
    }

    get transformedJobs() {
        return (this.jobs || [])
            .filter(job => {
                return !job.isManuallyCreated || job.manuallyCreatedFrom !== MANUALLY_CREATED_FROM.STAFFING_MODAL;
            })
            .map(job => {
            return {
                ...job,
                resourceRole: job.resourceRole,
                showAPTQuantity: job.resourceRole === 'VP/HH'
            }
        })
    }

    editJob(job) {
        let eventValues = {action: "edit", drive: this.drive, driveShift: this.shift, resourceType: this.resourceType, job: job};
        fireEvent(this.pageRef, 'showJobModal', eventValues);
    }
    
    bulkEditVolunteerJobs(job) {
        let eventValues = {action: "bulk-edit-volunteer-jobs", drive: this.drive, driveShift: this.shift, resourceType: this.resourceType, job: job};
        fireEvent(this.pageRef, 'showBulkEditVolunteerJobsModal', eventValues);
    }

    bulkAddVolunteerJobs(job) {
        let eventValues = {action: "bulk-add-volunteer-jobs", drive: this.drive, driveShift: this.shift, resourceType: this.resourceType, job: job};
        fireEvent(this.pageRef, 'showBulkEditVolunteerJobsModal', eventValues);
    }

    deleteJob(job) {
        let eventValues = {action: "deleteJob", driveShift: this.shift, resourceType: this.resourceType, job: job};
        fireEvent(this.pageRef, 'openDriveShiftConfirmModal', eventValues);
    }

    clickAction(event){
        const actionName = event.currentTarget.name
        const key = event.currentTarget.dataset.value
        const row = find(this.jobs,(item) => item.key === key)
        switch (actionName) {
            case 'edit':
                this.editJob(row);
                break;
            case 'bulk-edit-volunteer-jobs':
                this.bulkEditVolunteerJobs(row);
                break;
            case 'bulk-add-volunteer-jobs':
                this.bulkAddVolunteerJobs(row);
                break;
            case 'delete':
                this.deleteJob(row);
                break;
        }
    }

    handleRowActions(event) {
        let actionName = event.detail.action.name;
        let row = { ...event.detail.row };

        switch (actionName) {
            case 'edit':
                this.editJob(row);
                break;
            case 'bulk-edit-volunteer-jobs':
                this.bulkEditVolunteerJobs(row);
                break;
            case 'bulk-add-volunteer-jobs':
                this.bulkAddVolunteerJobs(row);
                break;
            case 'delete':
                this.deleteJob(row);
                break;
        }
    }
}