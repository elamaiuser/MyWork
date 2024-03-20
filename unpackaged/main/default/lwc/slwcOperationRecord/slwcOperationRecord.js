import {
    LightningElement,
    track,
    api,
    wire
} from 'lwc';
import {
    ShowToastEvent
} from 'lightning/platformShowToastEvent'
import {
    dataService,
    debugLogService,
    operationRecordService,
    operationRecordQueryModel
} from 'c/dataService';
import {
    CurrentPageReference
} from 'lightning/navigation';
import {
    each,
    findIndex,
    keyBy,
    mapKeys,
    remove,
    uniqueId,
    extend
} from 'c/lodash';
import {
    getValueFromEvent,
    classNames,
    isNullOrEmpty
} from 'c/slwcUtils';
import {
    DateTime
} from 'c/luxon';
import {
    DriveHelper
} from 'c/slwcDriveGenerator'

const SECTION = {
    OPERATION_DETAILS: 'operationDetails',
    DRIVE_INFORMATION: 'driveInformation',
    SITE_INFORMATION: 'siteInformation',
    DRIVE_ISSUES: 'driveIssues',
    LATE_END_DRIVE: 'lateEndDrive'
}
export default class SlwcOperationRecord extends LightningElement {
    SECTION = SECTION;

    @track _isOpen = false;
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

    @api job = null;
    @api jobAllocation = null;
    @api noReadonlyMode = false;
    @api fullScreen = false;

    @track model = {};
    @track hasOperationRecord = false;
    @track errorMessages = [];
    @track errorData = {};
    @track resourceRoleGroups = {};
    @track mapRoleToPremiumOpPay = {};
    @track adminSettings = {};

    @track showStaffModal = false;
    @track operationStaffSelected;
    @track operationStaffModalData = {};
    @track sectionExpandMap = {};
    @track isSubmit = false;
    
    @track confirmModalData = {};
    @track showSpinner = false;

    helper = new DriveHelper();

    @wire(CurrentPageReference) pageRef;

    get btnSaveDisabled() {
        return !this.hasOperationRecord;
    }

    get btnSubmitDisabled() {
        return !this.hasOperationRecord || this.opsRecordIntegrationDisabled;
    }
    
    get customClass() {
        return {
            modal: classNames('slds-modal slds-fade-in-open', {
                'full-screen': this.fullScreen
            }),
            operationDetailsSection: classNames('slds-accordion__section', {
                'slds-is-open': this.sectionExpandMap[SECTION.OPERATION_DETAILS] && this.sectionExpandMap[SECTION.OPERATION_DETAILS].expanded
            }),
            driveInformationSection: classNames('slds-accordion__section', {
                'slds-is-open': this.sectionExpandMap[SECTION.DRIVE_INFORMATION] && this.sectionExpandMap[SECTION.DRIVE_INFORMATION].expanded
            }),
            siteInformationSection: classNames('slds-accordion__section', {
                'slds-is-open': this.sectionExpandMap[SECTION.SITE_INFORMATION] && this.sectionExpandMap[SECTION.SITE_INFORMATION].expanded
            }),
            driveIssuesSection: classNames('slds-accordion__section', {
                'slds-is-open': this.sectionExpandMap[SECTION.DRIVE_ISSUES] && this.sectionExpandMap[SECTION.DRIVE_ISSUES].expanded
            }),
            lateEndDriveSection: classNames('slds-accordion__section', {
                'slds-is-open': this.sectionExpandMap[SECTION.LATE_END_DRIVE] && this.sectionExpandMap[SECTION.LATE_END_DRIVE].expanded
            })
        }
    }

    get hasStaffRecordList() {
        return this.model && this.model.operationRecordStaff && this.model.operationRecordStaff.length
    }

    get isAllowedToSubmit() {
        if(this.noReadonlyMode) return true;

        const supervisoryRoles = (this.resourceRoleGroups || {})['Supervisory roles'];
        if(!supervisoryRoles || !supervisoryRoles.length || !this.jobAllocation || this.showSubmittedStatus) return false;

        const isMainRoleSupervisory = supervisoryRoles.includes(this.jobAllocation.resourceRole);
        const isAdditionalRoleSupervisory = !!supervisoryRoles.find(role => (this.jobAllocation.additionalRoles || '').includes(role));
        return isMainRoleSupervisory || isAdditionalRoleSupervisory;
    }
    
    get isAnyDriveIssueChecked() {
        return this.model && (this.model.changedDriveLocation === true 
            || this.model.driveDelayed === true 
            || this.model.eBdrEquipmentProblemFailure === true 
            || this.model.improperRoomConditions === true 
            || this.model.limitedAccessToUnload === true 
            || this.model.missingEquipmentSupply === true 
            || this.model.roomNotAccessibleLocked === true 
            || this.model.securityProtocolIssue === true 
            || this.model.qcIssue === true 
            || this.model.setup === true 
            || this.model.staff === true
            || this.model.masterServerIssue === true
            || this.model.vehicleMalfunction === true
            || this.model.connectivity === true);
    }

    get isDriveIssueRequired() {
       return this.isAnyDriveIssueChecked;
    }

    get isReadonly() {
        if(this.noReadonlyMode) return false;

        const supervisoryRoles = (this.resourceRoleGroups || {})['Supervisory roles'];
        if(!supervisoryRoles || !supervisoryRoles.length || !this.jobAllocation || this.showSubmittedStatus) return true;

        const isMainRoleSupervisory = supervisoryRoles.includes(this.jobAllocation.resourceRole);
        const isAdditionalRoleSupervisory = !!supervisoryRoles.find(role => (this.jobAllocation.additionalRoles || '').includes(role));
        return !isMainRoleSupervisory && !isAdditionalRoleSupervisory;
    }

    get isReadyToSubmit() {
        return !this.showSpinner && !this.showSubmittedStatus && !this.isReadonly && this.validate(true, true) && this.isAllowedToSubmit;
    }

    get isSlow() {
        return this.model && this.model.connectivity &&
        this.model.connectivityReason == "Slow Network Performance"
    }

    get operationRecordStaffs() {
        return (this.model.operationRecordStaff || []).map(item => {
            item.customClass = {
                card: classNames('card slds-grid slds-grid--align-spread', {
                    'has-error': item.hasError
                })
            }
            return item;
        })
    }

    get showCreateOperationStaffBtn() {
        return !this.isReadonly && this.hasOperationRecord;
    }

    get showNoOperationRecordAlert() {
        return !this.showSpinner && !this.hasOperationRecord;
    }

    get showSubmittedStatus() {
        return this.model.status === 'Submitted';
    }

    get opsRecordIntegrationDisabled() {
        if(!this.adminSettings) return false;
        return !this.adminSettings.opsRecordIntegration;
    }

    connectedCallback() {
        // this.isOpen = true;
        // this.job = {
        //     driveShiftId: 'a1Z2i000001ifapEAA'
        // }
        // this.jobAllocation = {
        //     resourceRole: 'Charge'
        // }
        // this.init();
    }

    showLoading() {
        this.showSpinner = true;
    }

    hideLoading() {
        this.showSpinner = false;
    }

    init() {
        if(!this.job || !this.job.driveShiftId) {
            //TODO: handle error
            return;
        }
        
        //reset 
        this.isSubmit = false;
        this.model = {};
        this.hasOperationRecord = false;
        this.errorMessages = [];
        this.errorData = {};
        this.sectionExpandMap = {
            [SECTION.OPERATION_DETAILS]: {
                expanded: true
            },
            [SECTION.DRIVE_INFORMATION]: {
                expanded: false
            },
            [SECTION.SITE_INFORMATION]: {
                expanded: false
            },
            [SECTION.DRIVE_ISSUES]: {
                expanded: false
            },
            [SECTION.LATE_END_DRIVE]: {
                expanded: false
            }
        };
        this.errorData = {
            operationTab: false,
            relatedTab: false,
            operationDetails: false,
            driveInformation: false,
            siteInformation: false,
            driveIssues: false,
            lateEndDrive: false
        }

        Promise.all([
            this.retrieveCustomSettings(),
            this.fetchOperation(this.job.driveShiftId)
        ])
        .then(() => {
            return this.fetchExternalIds();
        })
    }

    closeModal(event, saved = false) {
        this.dispatchEvent(new CustomEvent('close', {
            detail: {
                result: saved
            }
        }));
    }

    validate(isSubmit, slientValidate = false) {
        const allValid = [
            ...this.template.querySelectorAll('lightning-input'), 
            ...this.template.querySelectorAll('lightning-combobox'),
            ...this.template.querySelectorAll('c-slwc-picklist')]
            .reduce((validSoFar, inputCmp) => {
                if(!slientValidate) {
                    inputCmp.reportValidity();
                }
                return validSoFar && inputCmp.checkValidity();
            }, true)

        let hasError = false;
        if(!slientValidate) {
            this.errorMessages = [];
            this.errorData = {
                operationTab: false,
                relatedTab: false,
                operationDetails: false,
                driveInformation: false,
                siteInformation: false,
                driveIssues: false,
                lateEndDrive: false,
                lateEndDriveAndRecordStaffNotMatched: false
            }
        }

        each(this.model, (value, key) => {
            if (key.includes('Reason') && this.model[key.replace('Reason', '')] && !value) {
                hasError = true;
                if(!slientValidate) {
                    this.errorData.operationTab = true;
                    this.errorData.driveIssues = true;
                }
            }
        })
        if (this.model && this.model["actualDriveStart"] && this.model["actualDriveEnd"] && (this.model["actualDriveEnd"] <= this.model["actualDriveStart"])) {
            hasError = true;
            if(!slientValidate) {
                this.errorMessages.push({
                    message: 'Actual Drive End should be greater than Actual Drive Start'
                })
                this.errorData.operationTab = true;
                this.errorData.driveInformation = true;
            }
        }
        if (this.model && this.model["powerRedMachinesUsed"] && this.model["powerRedMachinesSent"] && (this.model["powerRedMachinesUsed"] > this.model["powerRedMachinesSent"])) {
            hasError = true;
            if(!slientValidate) {
                this.errorMessages.push({
                    message: 'The # of machines used should always be equal to or less than the # sent'
                })
                this.errorData.operationTab = true;
                this.errorData.driveInformation = true;
            }
        }
        if (this.model && this.model["connectivity"] && this.isSlow) {
            each(["connectivityDetail", "connectivityTotalDevices", "connectivityNoOfIssueDevices", "connectivityClient", "connectivityHandheld", "connectivityZebra"], item => {
                if (isNullOrEmpty(this.model[item])) {
                    hasError = true;
                    if(!slientValidate) {
                        this.errorData.operationTab = true;
                        this.errorData.driveIssues = true;
                    }
                }
            })
        }
        if (this.model && this.model["eBdrEquipmentProblemFailure"]) {
            each(["eBdrMaster", "eBdrTotalDevices", "eBdrNoOfIssueDevices", "eBdrClient", "eBdrHandheld", "eBdrZebra"], item => {
                if (isNullOrEmpty(this.model[item])) {
                    hasError = true;
                    if(!slientValidate) {
                        this.errorData.operationTab = true;
                        this.errorData.driveIssues = true;
                    }
                }
            })
        }

        if (this.model["lateEndDrive"]) {
            if (!this.model['lateEndReason'] || !this.model['lateEndDriveApprovedBy']) {
                hasError = true;
                if(!slientValidate) {
                    this.errorData.operationTab = true;
                    this.errorData.lateEndDrive = true;
                }
            }
        }

        let anyOperationRecordStaffError = false;
        const ERROR_LATE_END_MISMATCHED = 'Late End recorded for the staff person is not consistent with the Late End Drive.';
        if (this.model["lateEndDrive"]) {
            // let atLeast1LateEndStaff = false;
            // (this.model.operationRecordStaff || []).forEach(operationStaff => {
            //     if(!slientValidate) {
            //         operationStaff.hasError = false;
            //         operationStaff.lateEndDriveAndRecordStaffNotMatched = false;
            //     }
                
            //     if(operationStaff.absent) return;

            //     if(operationStaff.premiumsOpPay && operationStaff.premiumsOpPay.includes('Late End')) {
            //         atLeast1LateEndStaff = true;
            //     }
            // })

            // if(!atLeast1LateEndStaff) {
            //     (this.model.operationRecordStaff || []).forEach(operationStaff => {
            //         if(operationStaff.absent) return;
    
            //         if(!slientValidate) {
            //             this.errorData.lateEndDrive = true;
            //             this.errorData.operationTab = true;

            //             if(!this.errorMessages.find(item => item.message === ERROR_LATE_END_MISMATCHED)) {
            //                 this.errorMessages.push({
            //                     message: ERROR_LATE_END_MISMATCHED
            //                 });
            //             }
            //         }
            //         hasError = true;
            //         anyOperationRecordStaffError = true;
            //     })
            // }
        } else {
            (this.model.operationRecordStaff || []).forEach(operationStaff => {
                if(!slientValidate) {
                    operationStaff.hasError = false;
                    operationStaff.lateEndDriveAndRecordStaffNotMatched = false;
                }
                if(operationStaff.absent) return;

                if(operationStaff.premiumsOpPay && operationStaff.premiumsOpPay.includes('Late End')) {
                    if(!slientValidate) {
                        operationStaff.hasError = true;
                        operationStaff.lateEndDriveAndRecordStaffNotMatched = true;

                        this.errorData.lateEndDrive = true;
                        this.errorData.operationTab = true;

                        if(!this.errorMessages.find(item => item.message === ERROR_LATE_END_MISMATCHED)) {
                            this.errorMessages.push({
                                message: ERROR_LATE_END_MISMATCHED
                            });
                        }
                    }
                    hasError = true;
                    anyOperationRecordStaffError = true;
                }
            })
        }

        if(anyOperationRecordStaffError) {
            if(!slientValidate) {
                this.errorData.relatedTab = true;
            }
        }

        if(isSubmit) {
            if (!this.model['actualDriveStart'] || !this.model['actualDriveEnd']) {
                hasError = true;
                if(!slientValidate) {
                    this.errorData.operationTab = true;
                    this.errorData.driveInformation = true;
                }
            }

            if (isNullOrEmpty(this.model['powerRedMachinesUsed']) || isNullOrEmpty(this.model['powerRedMachinesSent'])) {
                hasError = true;
                if(!slientValidate) {
                    this.errorData.operationTab = true;
                    this.errorData.driveInformation = true;
                }
            }

            if (isNullOrEmpty(this.model['donorAmbassadorsActual'])) {
                hasError = true;
                if(!slientValidate) {
                    this.errorData.operationTab = true;
                    this.errorData.driveInformation = true;

                    const ERROR_MISSING_DONOR_AMBASSADOR = 'Error: Missing donor ambassador';
                    if(!this.errorMessages.find(item => item.message === ERROR_MISSING_DONOR_AMBASSADOR)) {
                        this.errorMessages.push({
                            message: ERROR_MISSING_DONOR_AMBASSADOR
                        });
                    }
                }
            }

            let anyOperationRecordStaffError = false;
            (this.model.operationRecordStaff || []).forEach(operationStaff => {
                if(!slientValidate) {
                    operationStaff.hasError = false;
                }
                if(operationStaff.absent) {
                    return;
                }

                if((!operationStaff.actualShiftStart || !operationStaff.actualShiftEnd)) {
                    if(!slientValidate) {
                        operationStaff.hasError = true;
                    }
                    hasError = true;
                    anyOperationRecordStaffError = true;
                } else {
                    if(operationStaff.actualShiftEnd <= operationStaff.actualShiftStart) {
                        if(!slientValidate) {
                            operationStaff.hasError = true;
                        }
                        hasError = true;
                        anyOperationRecordStaffError = true;
                    } else {
                        const duration = DateTime.fromISO(operationStaff.actualShiftEnd, {
                            zone: this.model.timezoneSidId
                        }).diff(DateTime.fromISO(operationStaff.actualShiftStart, {
                            zone: this.model.timezoneSidId
                        })).as('minutes');

                        if (duration > 24 * 60) {
                            if (!slientValidate) {
                                operationStaff.hasError = true;
                            }
                            hasError = true;
                            anyOperationRecordStaffError = true;
                        }


                        let allowedDriveEndDate = this.model.driveDate;
                        let actualShiftStartDate = DateTime.fromISO(operationStaff.actualShiftStart, {
                            zone: this.model.timezoneSidId
                        }).toFormat('yyyy-MM-dd');
                        let actualShiftEndDate = DateTime.fromISO(operationStaff.actualShiftEnd, {
                            zone: this.model.timezoneSidId
                        }).toFormat('yyyy-MM-dd');
                        if (this.model.lateEndDrive) {
                            allowedDriveEndDate = DateTime.fromFormat(this.model.driveDate, 'yyyy-MM-dd').plus({
                                days: 1
                            }).toFormat('yyyy-MM-dd');
                        }

                        if (actualShiftStartDate !== this.model.driveDate) {
                            if (!slientValidate) {
                                operationStaff.hasError = true;
                            }
                            hasError = true;
                            anyOperationRecordStaffError = true;
                        }

                        if(actualShiftEndDate > allowedDriveEndDate) {
                            if (!slientValidate) {
                                operationStaff.hasError = true;
                            }
                            hasError = true;
                            anyOperationRecordStaffError = true;
                        }
                    }
                }

                if(!operationStaff.actualRoles || !operationStaff.actualRoles.length) {
                    if(!slientValidate) {
                        operationStaff.hasError = true;
                    }
                    hasError = true;
                    anyOperationRecordStaffError = true;
                }
            })

            const ERROR_DRIVE_ISSUES_MISMATCHED1 = 'Drive Issues is selected but none of issue checkboxes is checked';
            const ERROR_DRIVE_ISSUES_MISMATCHED2 = 'Drive Issues must be selected because some of issue checkboxes are checked';
            if (this.model['driveIssues']) {
                if(!this.isAnyDriveIssueChecked) {
                    if(!slientValidate) {
                        this.errorData.driveIssues = true;
                        this.errorData.operationTab = true;

                        if(!this.errorMessages.find(item => item.message === ERROR_DRIVE_ISSUES_MISMATCHED1)) {
                            this.errorMessages.push({
                                message: ERROR_DRIVE_ISSUES_MISMATCHED1
                            });
                        }
                    }
                    hasError = true;
                }
            } else {
                if(this.isAnyDriveIssueChecked) {
                    if(!slientValidate) {
                        this.errorData.driveIssues = true;
                        this.errorData.operationTab = true;

                        if(!this.errorMessages.find(item => item.message === ERROR_DRIVE_ISSUES_MISMATCHED2)) {
                            this.errorMessages.push({
                                message: ERROR_DRIVE_ISSUES_MISMATCHED2
                            });
                        }
                    }
                    hasError = true;
                }
            }

            if(anyOperationRecordStaffError) {
                if(!slientValidate) {
                    this.errorData.relatedTab = true;

                    const ERROR_SOME_STAFF_RECORD = 'Some Operation Record Staff records are invalid. Please check.'
                    if(!this.errorMessages.find(item => item.message === ERROR_SOME_STAFF_RECORD)) {
                        this.errorMessages.push({
                            message: ERROR_SOME_STAFF_RECORD
                        });
                    }
                }
            }
        }
        
        return allValid && !hasError;
    }

    formatTime(time) {
        let result = ''; 
        if (time) {
            result = DateTime.fromFormat(time, 'HH:mm:ss.SSS').toFormat('h:mm a');
        }
        return result;
    }

    handleOnChange(event) {
        console.log("handleOnChange", event);
        const eventName = event.target.name;
        const value = getValueFromEvent(event)
        this.model[eventName] = value

        this.validate(this.isSubmit);

        console.log("this.model[eventName]", this.model[eventName]);
    }

    handleSelectContact(event) {
        this.model.primaryContact = event.detail.selection
        this.model.primaryContactId = event.detail.selection.id
        this.model.primaryContactName = event.detail.selection.name
    }

    retrieveCustomSettings() {
        let settingKeys = ['resourceRoleGroups', 'mapRoleToPremiumOpPay', 'adminSetting'];
        return Promise.resolve()
        .then(() => {
            let service = new dataService();
            return service.getCustomSettings({ settingKeys: settingKeys })
            .then((result) => {
                this.adminSettings = result.returnedData.adminSetting;
                this.resourceRoleGroups = result.returnedData.resourceRoleGroups;
                this.mapRoleToPremiumOpPay = result.returnedData.mapRoleToPremiumOpPay;
            })
        });        
    }

    fetchOperation(driveShiftId) {
        let query = new operationRecordQueryModel();
        query.driveShiftIds = [driveShiftId];
        let service = new operationRecordService();
        this.showLoading();
        return service.query(query)
            .then(result => {
                if(!result || !result.length) return;

                this.hasOperationRecord = true;

                //handle error 
                this.model = {  
                    ...result[0],
                    driveStartTimeFormat: this.formatTime(result[0].driveStartTime),
                    driveEndTimeFormat: this.formatTime(result[0].driveEndTime),
                    driveShiftStartTimeFormat: this.formatTime(result[0].driveShiftStartTime),
                    driveShiftEndTimeFormat: this.formatTime(result[0].driveShiftEndTime),
                }

                this.model.driveStart = this.helper.newDateTime(this.model.driveDate, this.model.driveStartTime, this.model.timezoneSidId).toISOString();
                this.model.driveEnd = this.helper.newDateTime(this.model.driveDate, this.model.driveEndTime, this.model.timezoneSidId).toISOString();

                this.model.primaryContact = {
                    id: this.model.primaryContactId,
                    name: this.model.primaryContactName,
                };
            })
            .catch((error) => {
                new debugLogService().captureDebugLog(error, this.model?.id);
                this.dispatchEvent(new ShowToastEvent({
                  message: error.message,
                  variant: 'error',
                  mode: 'dismissable',
                }));
            })
            .finally(() => this.hideLoading())
    }

    fetchExternalIds() {
        let service = new operationRecordService();
        this.showLoading();
        return service.populateExternalIds({
            request: {
                recordId: this.model.id
            }
        })
            .then(result => {
                if(!result || !result.returnedData || !result.returnedData.length) return;

                this.model.driveExternalID = result.returnedData[0].sked_Drive_External_ID__c;
                this.model.accountExternalID = result.returnedData[0].sked_Account_External_ID__c;
                this.model.siteExternalID = result.returnedData[0].sked_Site_External_ID__c;
            })
            .catch((error) => {
                new debugLogService().captureDebugLog(error, this.model?.id);
                this.dispatchEvent(new ShowToastEvent({
                  message: error.message,
                  variant: 'error',
                  mode: 'dismissable',
                }));
            })
            .finally(() => this.hideLoading())
    }
    
    handleSubmit() {
        this.isSubmit = true;

        setTimeout(() => {
            if (this.validate(true)) {
                this.showConfirmModal({
                    title: 'Confirmation',
                    message: `Are you sure you want to submit? Submitted Op Records cannot be edited.`,
                    onClose: (result) => {
                        this.hideConfirmModal();
                        if (result) {
                            let service = new operationRecordService();
                            this.showLoading();

                            service.save(this.model)
                            .then(res => {
                                if (!res.success) throw res;
                                return service.submitOperationRecord({
                                    request: {
                                        operationRecordId: this.model.id
                                    }
                                });
                            })
                            .then(res => {
                                if (!res.success) throw res;
                                this.dispatchEvent(new ShowToastEvent({
                                    message: 'Operation were submitted successfully.',
                                    variant: 'success',
                                    mode: 'dismissable'
                                }));
                                this.init();
                                this.closeModal(null, true);
                            })
                            .catch((error) => {
                                let message = error.message ? error.message : 'Op Record failed submit: Retry submission or contact BSF support or system administrator for assistance.';
                                console.debug('Error while submitting operation record: ', error.returnedData);
                                new debugLogService().captureDebugLog(error, this.model?.id);
                                this.dispatchEvent(new ShowToastEvent({
                                    message: message,
                                    variant: 'error',
                                    mode: 'dismissable',
                                }));
                            })
                            .finally(() => this.hideLoading())
                        }
                    }
                });
            }
        })
    }
    handleSave() {
        this.isSubmit = false;

        setTimeout(() => {
            if (this.validate(false)) {
                let service = new operationRecordService();
                this.showLoading();
                console.log("this.model", this.model);
                service.save(this.model)
                .then(res => {
                    if (res.success) {
                        const event = new ShowToastEvent({
                            message: 'Operation were updated successfully.',
                            variant: 'success',
                            mode: 'dismissable'
                        });
                        this.dispatchEvent(event);

                        this.init();
                        this.closeModal(null, true);
                    } else {
                        const event = new ShowToastEvent({
                            message: res.returnedData,
                            variant: 'error',
                            mode: 'dismissable'
                        });
                        this.dispatchEvent(event);
                    }
                })
                .catch((error) => {
                    new debugLogService().captureDebugLog(error, this.model?.id);
                    this.dispatchEvent(new ShowToastEvent({
                      message: error.message,
                      variant: 'error',
                      mode: 'dismissable',
                    }));
                })
                .finally(() => this.hideLoading())
            }
        })
    }

    handleSaveOperationStaffModal = (event) => {
        let newRecord = event.detail;
        if(!newRecord) return;

        if(!this.model.operationRecordStaff) {
            this.model.operationRecordStaff = [];
        }

        let found = this.model.operationRecordStaff.find(item => item.key === newRecord.key);
        if (found) {
            found = extend(found, newRecord);
        } else {
            newRecord.addedStaff = true;
            newRecord.timezoneSidId = this.model.timezoneSidId;
            this.model.operationRecordStaff.push(newRecord);
        }

        this.validate(this.isSubmit);
        this.handleCloseOperationStaffModal();
    }

    editOperationStaff(event) {
        const key = event.currentTarget.dataset.key;
        let found = this.model.operationRecordStaff.find(item => item.key === key);
        this.handleShowOperationStaffModal(found)
    }

    createOperationStaff() {
        this.handleShowOperationStaffModal();
    }

    handleShowOperationStaffModal(record) {
        this.operationStaffModalData = {
            isOpen: true,
            record: record
        };
    }

    handleCloseOperationStaffModal() {
        this.operationStaffModalData = {};
    }

    toggleSection(event) {
        const section = event.currentTarget.dataset['value'];
        this.sectionExpandMap[section].expanded = !this.sectionExpandMap[section].expanded;
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