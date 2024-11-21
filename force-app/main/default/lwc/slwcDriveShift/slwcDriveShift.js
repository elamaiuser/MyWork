import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import * as slwcUtils from 'c/slwcUtils';
import { DriveHelper } from 'c/slwcDriveGenerator'

const CMP_NAME = 'slwcDriveShifts';
const DRIVE_DATA_CHANGED_EVENT = 'drivedatachanged';
import { DRIVE_TYPE, ASSET_TYPE } from 'c/slwcConstants';

export default class SlwcDriveShift extends LightningElement {
    driveHelper = new DriveHelper();

    @api showErrors;
    @api masterData;
    @api shift;
    @api drive;

    get isFixedSiteDrive() {
        return this.driveHelper.isFixedSiteDrive(this.drive);
    }

    get isLunchBreakReadonly(){
        return this.shift.lunchBreakBeforeDrawHours == true;
    }

    get title() {
        return (this.shift && this.shift.name) ? this.shift.name : "New Shift";
    }

    get slotsPerHour() {
        if (this.drive && this.shift) {
            let shiftStart = this.newDateTime(this.drive.driveDate, this.shift.startTime, this.masterData.timezoneSidId);
            let shiftEnd = this.newDateTime(this.drive.driveDate, this.shift.endTime, this.masterData.timezoneSidId);
            let drawHours = (shiftEnd.getTime() - shiftStart.getTime()) / 3600000;

            return this.shift.totalSlots / drawHours;
        }
    }

    get driveShiftTags() {
        let result = [];
        if (this.shift && this.shift.driveShiftTags && this.shift.driveShiftTags.length > 0) {
            this.shift.driveShiftTags.forEach((item) => {
                result.push(item);
            });
        }
        return result;
    }

    get personJobs() {
        let result = [];
        if (this.shift && this.shift.jobs && this.shift.jobs.length > 0) {
            this.shift.jobs.forEach((job) => {
                if (job.resourceRole) {
                    result.push(job);
                }
            });
        }
        return result;
    }

    get volunteerJobs() {
        let result = [];
        if (this.shift && this.shift.jobs && this.shift.jobs.length > 0) {
            this.shift.jobs.forEach((job) => {
                if (job.volunteerRole) {
                    result.push(job);
                }
            });
        }
        return result;
    }

    get vehicleJobs() {
        let result = [];
        if (this.shift && this.shift.jobs && this.shift.jobs.length > 0) {
            this.shift.jobs.forEach((job) => {
                if (job.assetType && job.assetType == ASSET_TYPE.VEHICLE) {
                    result.push(job);
                }
            });
        }
        return result;
    }

    get vehicleEnabled() {
        return this.shift && this.shift.jobs && this.shift.jobs.findIndex((job) => job.assetType && job.assetType == ASSET_TYPE.VEHICLE) > -1;
    }

    get equipmentComplementEditable() {
        return !this.isFixedSiteDrive;
    }

    get equipmentJobs() {
        let result = [];
        if (this.shift && this.shift.jobs && this.shift.jobs.length > 0) {
            this.shift.jobs.forEach((job) => {
                if (job.assetType && job.assetType == ASSET_TYPE.EQUIPMENT) {
                    result.push(job);
                }
            });
        }
        return result;
    }

    get equipmentEnabled() {
        return this.shift && this.shift.jobs && this.shift.jobs.findIndex((job) => job.assetType && job.assetType == ASSET_TYPE.EQUIPMENT) > -1;
    }
    
    get driveShiftStaffCapacity() {
        if(!this.shift || !this.shift.maxDonorCapacity) return 0;
        return Math.ceil(Number(this.shift.maxDonorCapacity));
    }

    @wire(CurrentPageReference) pageRef;

    renderedCallback() {
        if (this.showErrors == true) {
            this.showUiInputErrors()
        }
    }

    showUiInputErrors() {
        const allValid = [...this.template.querySelectorAll('lightning-input')]
                .reduce((validSoFar, inputCmp) => {
                            inputCmp.reportValidity();
                            return validSoFar && inputCmp.checkValidity();
                }, true);
        return allValid;
    }
    
    handleOnChange(event) {
        this.handleDispatchEvent(DRIVE_DATA_CHANGED_EVENT, this.shift.key, [
            {
                targetName: event.target.name, 
                targetValue: slwcUtils.getValueFromEvent(event)
            }
        ]);
    }

    handleDispatchEvent(eventName, key, properties) {
        this.dispatchEvent(
            new CustomEvent(eventName, {
                bubbles: true,
                composed: true,
                detail: {
                    key: key,
                    cmpName: CMP_NAME,
                    properties: properties
                }
            })
        );
    }

    /** Date Time Utils **/
    newDateTime(dateIso, timeIso, timezoneSidId) {
        let dateTimeIso = dateIso + 'T' + timeIso;
        let date = new Date(dateTimeIso);
        
        var invdate = new Date(date.toLocaleString('en-US', {
          timeZone: timezoneSidId
        }));
        
        var diff = date.getTime() - invdate.getTime();
      
        return new Date(date.getTime() + diff);
    }
}