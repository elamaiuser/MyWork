import { LightningElement, api, track } from "lwc";
import { classNames } from 'c/slwcUtils';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { uniq, groupBy } from "c/lodash";
import TIME_ZONE from '@salesforce/i18n/timeZone';

export default class SlwcDriveOptimizeConfirmDriveList extends LightningElement {

  _selectedDrives = [];
  _currentSelectedDrives = [];

  @track sectionExpanded = true;
  @api drives = [];
  @api groupName;

  get selectedDrives() {
    return this._selectedDrives;
  }

  @api 
  set selectedDrives(value) {
    let selectedIds = (value || []).map(drive => drive.id);
    this._currentSelectedDrives = this.drives.filter(drive => selectedIds.includes(drive.id));
    this._selectedDrives = this._currentSelectedDrives.map(drive => drive.id);
  }

  get sectionClass() {
    return classNames('slds-section', {
      'slds-is-open': this.sectionExpanded
    })
  }

  get columns() {
    let results = [];
    results.push({
      label: "Drive Date",
      fieldName: "driveDate",
      type: "date-local",
      typeAttributes: { year: "numeric", month: "short", day: "2-digit" },
      hideDefaultActions: true
    });
    results.push({
      label: "Drive Name",
      fieldName: "recordPageUrl",
      type: "url",
      hideDefaultActions: false,
      wrapText: true,
      typeAttributes: { label: { fieldName: "name" }, target: "_blank" },
      hideDefaultActions: true
    });
    results.push({
      label: "Optimization Status",
      fieldName: "optimizationStatus",
      type: "text",
      hideDefaultActions: true,
      wrapText: true
    });
    results.push({
      label: "Event Type",
      fieldName: "typeOfDrive",
      type: "text",
      hideDefaultActions: true,
      wrapText: true
    });
    results.push({
      label: "Vehicle Types",
      fieldName: "vehicleTypes",
      type: "text",
      hideDefaultActions: true,
      wrapText: true
    });
    results.push({
      label: "Min Shift Start",
      fieldName: "minShiftStart",
      type: "date",
      typeAttributes: {
        hour: "numeric",
        minute: "2-digit",
        timeZone: TIME_ZONE
      },
      hideDefaultActions: true
    });
    results.push({
      label: "Max Shift End",
      fieldName: "maxShiftEnd",
      type: "date",
      typeAttributes: {
        hour: "numeric",
        minute: "2-digit",
        timeZone: TIME_ZONE
      },
      hideDefaultActions: true
    });
    results.push({
      label: "Staff Requested",
      fieldName: "totalStaffRequested",
      type: "number",
      cellAttributes: { alignment: "left" },
      hideDefaultActions: true
    });
    results.push({
      label: "Staff Scheduled",
      fieldName: "staffAllocated",
      type: "number",
      cellAttributes: { alignment: "left" },
      hideDefaultActions: true
    });
    return results;
  }

  get driveTypes() {
    let drivesbyType = groupBy(this.drives, drive => drive.typeOfDrive);
    
    return Object.keys(drivesbyType).map(key => {
      return {
        type : key,
        collectionOperationNames : uniq(drivesbyType[key].map(drive => `${key} - ${drive.collectionOperation.name}`))
      }
    })
  }

  toggleSection = () => {
    this.sectionExpanded = !this.sectionExpanded;
  }

  handleRowSelection(event) {
    this._currentSelectedDrives = event.detail.selectedRows || [];
  }

  handleOptimize() {
    if (!this._currentSelectedDrives || this._currentSelectedDrives.length === 0) {
      this.dispatchEvent(new ShowToastEvent({
        message: 'Need at least 1 drive to optimize.',
        variant: 'error',
        mode: 'dismissable'
      }));
      return;
    }

    this.dispatchEvent(new CustomEvent('optimize', 
      {
        detail: 
        {
          selectedDrives: this._currentSelectedDrives 
        }
      }));
  }
}