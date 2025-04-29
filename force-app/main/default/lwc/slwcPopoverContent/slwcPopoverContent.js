import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import resourceCapacityPopover from './resourceCapacityPopover.html';
import calendarCardPopover from './calendarCardPopover.html';
import driveDateDetailsPopover from './driveDateDetailsPopover.html';
import resourceTagPopover from './resourceTagPopover.html';
import dropdownList from './dropdownList.html';
import jobAllocationPopover from './jobAllocationPopover.html';
import linkedDriveJobAllocationPopover from './linkedDriveJobAllocationPopover.html';
import planDriveValidationPopover from './planDriveValidationPopover.html';
import driveShiftStaffComplementPopover from './driveShiftStaffComplementPopover.html';
import linkedDrivePopover from './linkedDrivePopover.html';
import driveShiftTagExceptionPopover from './driveShiftTagExceptionPopover.html';
import driveShiftResourceAllocationPopover from './driveShiftResourceAllocationPopover.html';
import { fireEvent } from 'c/pubsub';
import { JOB_ALLOCATION_STATUS, MANUALLY_CREATED_FROM } from 'c/slwcConstants';
import { DateTime } from 'c/luxon';
import { DriveHelper } from 'c/slwcDriveGenerator';

export default class SlwcPopoverContent extends LightningElement {
    driveHelper = new DriveHelper();

    @api name = null
    @api popoverData = null;
    @api timezone = null;
    @api readOnly = false;
    @api disabledCallOut = false;
    
    @wire(CurrentPageReference) pageRef;

    popoverContentMap = {
      'resourceCapacityPopover': resourceCapacityPopover,
      'calendarCardPopover': calendarCardPopover,
      'driveDateDetailsPopover': driveDateDetailsPopover,
      'resourceTagPopover': resourceTagPopover,
      'jobAllocationPopover': jobAllocationPopover,
      'linkedDriveJobAllocationPopover': linkedDriveJobAllocationPopover,
      'dropdownList': dropdownList,
      'planDriveValidationPopover': planDriveValidationPopover,
      'driveShiftStaffComplementPopover': driveShiftStaffComplementPopover,
      'linkedDrivePopover': linkedDrivePopover,
      'driveShiftTagExceptionPopover': driveShiftTagExceptionPopover,
      'driveShiftResourceAllocationPopover': driveShiftResourceAllocationPopover
    }
    get isShowCallOut(){
      return ![
        JOB_ALLOCATION_STATUS.PENDING_DISPATCH,
        JOB_ALLOCATION_STATUS.COMPLETE,
        JOB_ALLOCATION_STATUS.DECLINED,
        JOB_ALLOCATION_STATUS.DELETED
      ].includes(this.popoverData.status) && this.popoverData.id;
    }
    get isPerson() {
      return this.popoverData && this.popoverData.resource && this.popoverData.resource.resourceType == "Person"
    }
    get driveShiftStaffComplementTableColumns() {
      let columns = [];

      columns.push({ label: 'Resource Role', fieldName: 'resourceRole', type: 'text', initialWidth: 140, wrapText: true });     
      columns.push({ label: 'Dual Role', fieldName: 'dualRole', type: 'text', initialWidth: 120, wrapText: true });     
      columns.push({ label: 'Lead', fieldName: 'leadTime', type: 'number', initialWidth: 55, hideDefaultActions: true, cellAttributes: { alignment: 'left' } });
      columns.push({ label: 'Travel', fieldName: 'travelTime', type: 'number', initialWidth: 65, hideDefaultActions: true, cellAttributes: { alignment: 'left' } });
      columns.push({ label: 'Site Logistics To', fieldName: 'siteLogisticsTo', type: 'number', initialWidth: 65, hideDefaultActions: true, cellAttributes: { alignment: 'left' } });
      columns.push({ label: 'Setup', fieldName: 'setupTime', type: 'number', initialWidth: 65, hideDefaultActions: true, cellAttributes: { alignment: 'left' } });
      columns.push({ label: 'Breakdown', fieldName: 'breakdownTime', type: 'number', initialWidth: 85, hideDefaultActions: true, cellAttributes: { alignment: 'left' } });
      columns.push({ label: 'Wrap-up', fieldName: 'wrapUpTime', type: 'number', initialWidth: 75, hideDefaultActions: true, cellAttributes: { alignment: 'left' } });
      columns.push({ label: 'Travel', fieldName: 'travelTime2', type: 'number', initialWidth: 65, hideDefaultActions: true, cellAttributes: { alignment: 'left' } });
      columns.push({ label: 'Site Logistics Back', fieldName: 'siteLogisticsBack', type: 'number', initialWidth: 65, hideDefaultActions: true, cellAttributes: { alignment: 'left' } });

      return columns;
    }
    get driveShiftStaffComplementJobs() {
      let result = [];
      if (this.popoverData && this.popoverData.jobs && this.popoverData.jobs.length > 0) {
          this.popoverData.jobs.forEach((job) => {
              if(job.isManuallyCreated && job.manuallyCreatedFrom === MANUALLY_CREATED_FROM.STAFFING_MODAL) return;
              if (job.resourceRole && job.isShown) {
                result.push({
                  ...job,
                  resourceRole: job.resourceRole
                });
              }
          });
      }
      return result;
    }
    get jobAllocationStartWithTravelTime() {
      if(!this.popoverData) return null;
      return this.popoverData.start;
    }
    get jobAllocationEndWithTravelTime() {
      if(!this.popoverData) return null;
      return this.popoverData.end;
    }
    get driveShiftResourceAllocationColumns() {
      return [
        { label: 'Resource Name', fieldName: 'resourceName', type: 'text' },        
        { label: 'Resource Role', fieldName: 'resourceRole', type: 'text' }
      ];
    }
    get resourceAllocations() {      
      let allocations = [];
      if (this.popoverData && this.popoverData.jobs && this.popoverData.jobs.length > 0) {
        this.popoverData.jobs.forEach(job => {
          const resAllocations = [];
          job.jobAllocations.forEach(allocation => {
            if (allocation.status != JOB_ALLOCATION_STATUS.DELETED) {
              resAllocations.push({
                id: allocation.id || allocation.key,
                resourceName: allocation.resourceName || allocation.resource.name,                
                resourceRole: job.resourceRoleText || job.assetType                
              });
            }
          });
          resAllocations.sort((a, b) => a.resourceName.localeCompare(b.resourceName));
          allocations = allocations.concat(resAllocations);
        });
      }
      return allocations;
    }

    render() {
      return this.popoverContentMap[this.name];
    }

    hidePopover() {
      fireEvent(this.pageRef, 'popover:event', {
        event: 'popover:hideAll'
      });
    }

    handleCalendarCardAction(event) {
      const actionName = event.target.dataset.action;
      const action = this.popoverData.actions.find(item => item.label === actionName);
      if(action) {
        this.hidePopover();
        action.callback(this.popoverData.record, this.pageRef);
      }
    }

    handleJobAllocationPopoverAction(event) {
      this.hidePopover();

      const actionName = event.currentTarget.dataset.action;
      const actionEvent = new CustomEvent('action', {
        bubbles: true,
        composed: true,
        detail: {
          record: this.popoverData,
          action: actionName
        }
      });
      this.dispatchEvent(actionEvent);
    }

    handleAddRolePopoverAction(event) {
      this.hidePopover();

      let eventValues = {
        resource: this.popoverData.resource,
        jobAllocation: this.popoverData,
        jobId: this.popoverData.jobId
      };
      fireEvent(this.pageRef, 'showAddRoleModal', eventValues);
    }

    handleLinkedDrivePopoverAction(event) {
      this.hidePopover();

      const actionName = event.currentTarget.dataset.action;
      const actionEvent = new CustomEvent('action', {
        bubbles: true,
        composed: true,
        detail: {
          record: this.popoverData,
          action: actionName
        }
      });
      this.dispatchEvent(actionEvent);
    }
}