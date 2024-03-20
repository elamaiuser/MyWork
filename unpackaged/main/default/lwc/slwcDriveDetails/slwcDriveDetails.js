import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import * as slwcUtils from 'c/slwcUtils';
import { DRIVE_TYPE } from 'c/slwcConstants';
import { driveService } from 'c/dataService';
import * as autoMapper from 'c/autoMapper';
import { DriveHelper } from 'c/slwcDriveGenerator';
import TIME_ZONE from '@salesforce/i18n/timeZone';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const CMP_NAME = 'slwcDriveDetails';
const DRIVE_DATA_CHANGED_EVENT = 'drivedatachanged';

export default class SlwcDriveDetails extends NavigationMixin(LightningElement) {
    driveHelper = new DriveHelper();

    @api recordId;
    @api drive;
    @api masterData;
    @api showErrors = false;

    @track showSpinner = false;
    @track confirmModalData = {};

    get isFixedSiteDrive() {
        return this.driveHelper.isFixedSiteDrive(this.drive);
    }

    get accountName() {
        if (this.drive && this.drive.account) {
            return this.drive.account.name;
        }
        return "";
    }

    get driveOwnerName() {
        if (this.drive && this.drive.driveOwner) {
            return this.drive.driveOwner.name;
        }
        return "";
    }

    get siteInspectionCompletedByName() {
        if (this.drive.driveSite && this.drive.driveSite.siteInspectionCompletedBy) {
            return this.drive.driveSite.siteInspectionCompletedBy.name;
        }
        return "";
    }
    
    /* PAGE REFERENCE */
    @wire(CurrentPageReference) pageRef;

    renderedCallback() {
        if (this.showErrors) {
            this.showUiInputErrors()
        }
    }

    showLoading = () => {
        this.showSpinner = true;
    }

    hideLoading = () => {
        this.showSpinner = false;
    }

    showUiInputErrors() {
        const allValid = [...this.template.querySelectorAll('lightning-input'), ...this.template.querySelectorAll('lightning-combobox')]
                .reduce((validSoFar, inputCmp) => {
                            inputCmp.reportValidity();
                            return validSoFar && inputCmp.checkValidity();
                }, true);
        return allValid;
    }

    /* ON CHANGE HANDLERS */
    handleOnChange(event) {
        let targetName = event.target.name;
        let targetValue = slwcUtils.getValueFromEvent(event);
       
        clearTimeout(this.timeoutId); // no-op if invalid id
        this.timeoutId = setTimeout(() => {
            
            this.handleDispatchEvent(DRIVE_DATA_CHANGED_EVENT, [
                {
                    targetName: targetName, 
                    targetValue: targetValue
                }
            ]);
        }, 800);
    }

    handleSelectAccount(event) {
        this.handleLookupChanged(event, 'account');
    }

    handleBeforeRemoveSite = () => {
        return new Promise((resolve, reject) => {
            if(this.masterData.fieldChangeRestrictionMap.driveSite) {
                resolve(false);

                this.showConfirmModal({
                    title: 'Drive Site Change Restricted',
                    message: 'System does not allow to change Drive Site. The drive must be cancelled and rescheduled to make this site change.\nDo you want to continue to cancel the Drive?',
                    confirmBtnLabel: 'Yes',
                    cancelBtnLabel: 'No',
                    onClose: (result) => {
                        this.hideConfirmModal();
                        if(result) {
                            this.cancelDrive(this.drive);
                        }
                    }
                });
            } else {
                resolve(true);
            }
        });
    }

    handleSearchSites = (searchData) => {
        const queryText = searchData.searchTerm;
        let service = new driveService();
        let request = {
            collectionOperationId: this.drive.collectionOperationId,
            inputDate: this.drive.driveDate,
            queryText: queryText
        };
    
        return service.searchDriveSite({
          request: request
        }).then((result) => {
          if(!result || !result.returnedData) return [];
          return autoMapper.autoMapperInstance.mapToArray('sked__Location__c', result.returnedData.sites);
        });
    }

    handleSelectSite(event) {
        if(!event.detail.selection) {
            return;   
        }

        this.handleLookupChanged(event, 'driveSite');
    }

    handleSelectContact(event) {
        this.handleLookupChanged(event, 'primaryContact');
    }

    handleSelectDriveOwner(event) {
        this.handleLookupChanged(event, 'driveOwner');
    }

    handleLookupChanged(event, propertyName) {
        if (event.detail && event.detail.selection) {
            this.handleDispatchEvent(DRIVE_DATA_CHANGED_EVENT, [
                {
                    targetName: propertyName, 
                    targetValue: event.detail.selection
                },
                {
                    targetName: propertyName + 'Id', 
                    targetValue: event.detail.selection.id
                }
            ]);
        }
    }
    
    handleDispatchEvent(eventName, properties) {
        this.dispatchEvent(
            new CustomEvent(eventName, {
                bubbles: true,
                composed: true,
                detail: {
                    cmpName: CMP_NAME,
                    properties: properties
                }
            })
        );
    }
    
    cancelDrive = (drive) => {
        let driveHelper = new DriveHelper();
        let driveToSave = driveHelper.cancelDrive(drive, {
            timezoneSidId: TIME_ZONE,
            cancellationReason: 'System Need'
        });
        let service = new driveService();
        this.showLoading();
        return service.save(driveToSave)
            .then((result) => {
                if(!result || !result.success) {
                    throw result;
                }

                this.dispatchEvent(new ShowToastEvent({
                    message: 'Cancelled Drive successfully.',
                    variant: 'success',
                    mode: 'dismissable'
                }));

                //refresh page
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: this.recordId,
                        actionName: 'view'
                    }
                });
            })
            .catch((error) => {
                this.dispatchEvent(new ShowToastEvent({
                    message: error.message,
                    variant: 'error',
                    mode: 'dismissable',
                }));
            })
            .finally(() => this.hideLoading());
    }

    /** Confirm Modal **/
    showConfirmModal(confirmModalData) {
        this.confirmModalData = {...confirmModalData,
            isOpen: true,
            confirmBtnLabel: confirmModalData.confirmBtnLabel || 'Yes',
            cancelBtnLabel: confirmModalData.cancelBtnLabel || 'No',
        }
    }
    
    hideConfirmModal() {
        this.confirmModalData = {};
    }
}