import { LightningElement, api, track } from 'lwc';
import { classNames, serial } from 'c/slwcUtils';
import { driveService, jobAllocationService, jobAllocationQueryModel } from 'c/dataService';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { JOB_ALLOCATION_STATUS, RESOURCE_TYPE } from 'c/slwcConstants';
import { orderBy, chunk } from 'c/lodash';

export default class SlwcDispatchDriveModal extends LightningElement {
  _isOpen = true;
  @api
  get isOpen() {
    return this._isOpen;
  }
  set isOpen(value) {
    this._isOpen = value;
    
    if(this._isOpen) {
      this.init();
    }
  }
  
  @api drives = [];

  @track showCheckingSpinner = false;
  @track showSpinner = false;
  @track notifiedJobAllocations = [];
  @track progressBarData = {};

  get showingModal() {
    return !this.showCheckingSpinner && this.isOpen; 
  }
  
  get customClass() {
    return {
      modalClass: classNames('slds-modal', `slds-modal_medium`, {
        'slds-fade-in-open': this.showingModal
      }),
      headerClass: classNames('slds-modal__header', {
      }),
      footerClass: classNames('slds-modal__footer', {
      }),
      backdropClass: classNames('slds-backdrop', {
        'slds-backdrop_open': this.showingModal
      })
    }
  }
  
  get customStyle() {
    return {
      modalStyle: [
        `z-index: 9991`
      ].join(';'),
      backdropStyle: [
        `z-index: 9990`
      ].join(';')
    }
  };

  get groupedDrives() {
    let jobAllocations = this.notifiedJobAllocations || [];
    let sortedJobAllocations = orderBy(jobAllocations, [(ja) => {
      return ja.driveName + ' - ' + ja.driveUfid;
    }, 'resourceRole', 'resource.name'], ['asc', 'asc', 'asc']);
    let groupedDrives = [];
    let driveMap = {};
    sortedJobAllocations.forEach(jobAllocation => {
      const driveName = jobAllocation.driveName + ' - ' + jobAllocation.driveUfid;
      const resourceRole = jobAllocation.resourceRole;

      if(!resourceRole || !driveName) return;

      let foundDrive = driveMap[driveName];
      if(!foundDrive) {
        driveMap[driveName] = {
          name: driveName,
          resourceRoles: [],
          resourceRoleMap: {}
        }
        groupedDrives.push(driveMap[driveName]);
      }

      let foundResourceRole = driveMap[driveName].resourceRoleMap[resourceRole];
      if(!foundResourceRole) {
        driveMap[driveName].resourceRoleMap[resourceRole] = {
          name: resourceRole,
          jobAllocations: []
        }

        driveMap[driveName].resourceRoles.push(driveMap[driveName].resourceRoleMap[resourceRole]);
      }

      driveMap[driveName].resourceRoleMap[resourceRole].jobAllocations.push(jobAllocation);
    });

    return groupedDrives;
  }

  connectedCallback() {
    this.init();
  }

  showLoading() {
    this.showSpinner = true;
  }

  hideLoading() {
    this.showSpinner = false;
  }

  showProgressBar({
    message,
    processedRecords = 0,
    totalRecords = 0
  }) {
    this.progressBarData = {
      isOpen: true,
      message,
      processedRecords,
      totalRecords
    }
  }

  updateProgressBar({ message, processedRecords }) {
    this.progressBarData = {
      ...this.progressBarData,
      message,
      processedRecords
    }
  }

  hideProgressBar() {
    this.progressBarData = {}
  }

  showCheckDrivesLoading() {
    this.showCheckingSpinner = true;
  }

  hideCheckDrivesLoading() {
    this.showCheckingSpinner = false;
  }
  
  init() {
    if(!this.drives || !this.drives.length) {
      return;
    }

    this.showCheckDrivesLoading();
    this.checkDrives()
    .then(() => {
      if(!this.notifiedJobAllocations.length) {
        this.hideCheckDrivesLoading();
        this.handleConfirm({
          currentTarget: {
            dataset: {
              value: 'true'
            }
          }
        });
      }
    })
    .catch((error) => {
      this.dispatchEvent(new ShowToastEvent({
        message: error.message,
        variant: 'error',
        mode: 'dismissable',
      }));
    })
    .finally(() => this.hideCheckDrivesLoading())
  }

  checkDrives = () => {
    return Promise.resolve()
    .then(() => {
      let JAService = new jobAllocationService();
      let JAQueryModel = new jobAllocationQueryModel();
      JAQueryModel.driveIds = this.drives.map(drive => drive.id);
      JAQueryModel.statuses = [JOB_ALLOCATION_STATUS.DISPATCHED, JOB_ALLOCATION_STATUS.CONFIRMED, JOB_ALLOCATION_STATUS.EN_ROUTE, JOB_ALLOCATION_STATUS.CHECKED_IN, JOB_ALLOCATION_STATUS.IN_PROGRESS];
      JAQueryModel.resourceTypes = [RESOURCE_TYPE.PERSON];
      return JAService.query(JAQueryModel);
    })
    .then((jobAllocations) => {
      this.notifiedJobAllocations = jobAllocations || [];
    })
  }

  dispatchDrives = (resendAll) => {
    const DRIVES_PER_CHUNK = 5;
    const service = new driveService();
    const promises = chunk(this.drives, DRIVES_PER_CHUNK).map(drivesChunk => {
      return () => {
        this.updateProgressBar({
          processedRecords: this.progressBarData.processedRecords + drivesChunk.length
        });
        return service.dispatchDrives({
          request: {
            driveIds: drivesChunk.map(drive => drive.id),
            resend: resendAll
          }
        });
      }
    });


    return Promise.resolve()
    .then(() => {
      return serial(promises);
    })
    .then(() => {
      this.isOpen = false;

      this.dispatchEvent(new ShowToastEvent({
        message: 'Dispatch Drive(s) successfully.',
        variant: 'success',
        mode: 'dismissable'
      }));
      
      const closeEvent = new CustomEvent('close', {
        detail: {
          result: true
        }
      });
      this.dispatchEvent(closeEvent);
    })
  }

  handleConfirm = (event) => {
    const resendAll = event.currentTarget.dataset['value'] === 'true';
    return Promise.resolve()
    .then(() => {
      this.showProgressBar({
        message: 'Dispatching...',
        totalRecords: this.drives.length
      });
      return this.dispatchDrives(resendAll);
    })
    .catch((error) => {
      this.dispatchEvent(new ShowToastEvent({
        message: error.message,
        variant: 'error',
        mode: 'dismissable',
      }));
    })
    .finally(() => this.hideProgressBar())
  }

  handleCancel = () => {
    this.isOpen = false;

    const closeEvent = new CustomEvent('close', {
      detail: {
        result: false
      }
    });
    this.dispatchEvent(closeEvent);
  }
}