import { LightningElement, track, api, wire } from 'lwc';
import { classNames, getValueFromEvent, generateUUID } from 'c/slwcUtils';
import { CurrentPageReference } from 'lightning/navigation';
import { cloneDeep, orderBy, find } from 'c/lodash';
import { SLOT_TYPE, DRIVE_TYPE, OPERATION_TYPE } from 'c/slwcConstants';
import * as slwcUtils from 'c/slwcUtils';
import { fireEvent, registerListener, unregisterAllListeners } from 'c/pubsub';
import { DriveHelper } from 'c/slwcDriveGenerator'
export default class SlwcDriveAppointmentSlots extends LightningElement {
    driveHelper = new DriveHelper();

    @track slots = [];
    @track masterData;
    @track _2rbcSlots = [];
    @track wbSlots = [];
    @track plateletSlots = [];
    @track plasmaSlots = [];
    @track selectedSlot;
    @track confirmModalData = {};
    @track confirmDeleteSlotData = {};
    @track startTimeOptions = {};
    @track lockAppointmentModalData = {};

    @api drive;
    @api driveShift;
    @wire(CurrentPageReference) pageRef;

    @api
    set slotsData(input) {
        this.slots = input;

        if (this.slots && this.slots.length > 0) {
            
            this._2rbcSlots = [];
            this.wbSlots = [];
            this.plateletSlots = [];
            this.plasmaSlots = [];
            
            orderBy(this.slots, ['startTime'], ['asc']).forEach((slot) => {
                if (slot.slotType == SLOT_TYPE._2RBC) {
                    this._2rbcSlots.push(slot);
                } else if (slot.slotType == SLOT_TYPE.WB) {
                    this.wbSlots.push(slot);
                } else if (slot.slotType == SLOT_TYPE.PLATELET) {
                    this.plateletSlots.push(slot);
                } else if (slot.slotType == SLOT_TYPE.PLASMA) {
                    this.plasmaSlots.push(slot);
                }
            });
        }
    }

    get slotsData() {
        return this.slots;
    }

    get isCreateable() {
        if (this.isFixedSiteDrive && this.masterData && this.masterData.loginUser 
            && (this.masterData.loginUser.profileName === 'DRD Manager' || this.masterData.loginUser.profileName === 'DRD Profile')) {
                return false;
        }else if (this.masterData && this.masterData.loginUser && this.masterData.loginUser.slotPermission) {
            return this.masterData.loginUser.slotPermission.isCreateable;
        }
        return false;
    }

    get isUpdateable() {
        if (this.isFixedSiteDrive && this.masterData && this.masterData.loginUser 
            && (this.masterData.loginUser.profileName === 'DRD Manager' || this.masterData.loginUser.profileName === 'DRD Profile')) {
                return false;
        }else if (this.masterData && this.masterData.loginUser && this.masterData.loginUser.slotPermission) {
            return this.masterData.loginUser.slotPermission.isUpdateable;
        }
        return false;
    }

    get isDeletable() {
        if (this.isFixedSiteDrive && this.masterData && this.masterData.loginUser 
            && (this.masterData.loginUser.profileName === 'DRD Manager' || this.masterData.loginUser.profileName === 'DRD Profile')) {
                return false;
        }else if (this.masterData && this.masterData.loginUser && this.masterData.loginUser.slotPermission) {
            return this.masterData.loginUser.slotPermission.isDeletable;
        }
        return false;
    }

    get isMobile(){
        return slwcUtils.isMobile()
    }

    get isFixedSiteDrive() {
        return this.driveHelper.isFixedSiteDrive(this.drive);
    }
    
    get allowToInputLockReason() {
        // return true;
        return this.driveHelper.isFixedSiteDrive(this.drive) || this.driveHelper.isWbFixedSiteDrive(this.drive);
    }

    get selectedSlots() {
        return this.slots.filter(slot => slot.selected);
    }

    get disableLockAppointments() {
        return !this.selectedSlots.length;
    }

    get displaySlotsData() {
        const selectedSlot = this.selectedSlot;

        let result = [];
        if(this.isFixedSiteDrive && 
            [OPERATION_TYPE.INTEGRATED, OPERATION_TYPE.NON_INTEGRATED_APH].includes(this.drive.operationType)) {
            result.push({
                label: SLOT_TYPE.PLATELET,
                slotType: SLOT_TYPE.PLATELET,
                slots: orderBy(this.plateletSlots
                    .map(item => {
                        var temp = {...item};
                        temp.class = classNames({
                            'locked': temp.locked,
                            'selected': selectedSlot && temp.key === selectedSlot.key
                        })
                        return temp;
                    }), ['startTime', 'endTime'], ['asc', 'asc']),
                show: true,
                totalAppointments: this.plateletSlots.length,
                defaultSlots: this.driveShift.defaultPlateletSlots,
                slotsAboveDefault: this.plateletSlots.length - this.driveShift.defaultPlateletSlots,
                class: classNames('slds-has-dividers_around-space appointment-slots platelet')
            })

            result.push({
                label: SLOT_TYPE.PLASMA,
                slotType: SLOT_TYPE.PLASMA,
                slots: orderBy(this.plasmaSlots
                    .map(item => {
                        var temp = {...item};
                        temp.class = classNames({
                            'locked': temp.locked,
                            'selected': selectedSlot && temp.key === selectedSlot.key
                        })
                        return temp;
                    }), ['startTime', 'endTime'], ['asc', 'asc']),
                show: true,
                totalAppointments: this.plasmaSlots.length,
                defaultSlots: this.driveShift.defaultPlasmaSlots,
                slotsAboveDefault: this.plasmaSlots.length - this.driveShift.defaultPlasmaSlots,
                class: classNames('slds-has-dividers_around-space appointment-slots plasma')
            })
        }

        if(!this.isFixedSiteDrive || 
            [OPERATION_TYPE.INTEGRATED, OPERATION_TYPE.NON_INTEGRATED_WB].includes(this.drive.operationType)) {

            result.push({
                label: 'Whole Blood',
                slotType: SLOT_TYPE.WB,
                slots: orderBy(this.wbSlots
                    .map(item => {
                        var temp = {...item};
                        temp.class = classNames({
                            'locked': temp.locked,
                            'selected': selectedSlot && temp.key === selectedSlot.key
                        })
                        return temp;
                    }), ['startTime', 'endTime'], ['asc', 'asc']),
                show: this.wbSlots,
                totalAppointments: this.wbSlots.length,
                defaultSlots: this.driveShift.defaultWbSlots,
                slotsAboveDefault: this.wbSlots.length - this.driveShift.defaultWbSlots,
                class: classNames('slds-has-dividers_around-space appointment-slots whole-blood')
            })

            if (this.isFixedSiteDrive || (this.drive && this.drive.x2rbcProjectedProcedures)) {
                result.push(
                    {
                        label: 'Power Red',
                        slotType: SLOT_TYPE._2RBC,
                        slots:  orderBy(this._2rbcSlots
                            .map(item => {
                                var temp = {...item};
                                temp.class = classNames({
                                    'locked': temp.locked,
                                    'selected': selectedSlot && temp.key === selectedSlot.key
                                })
                                return temp;
                            }), ['startTime', 'endTime'], ['asc', 'asc']),
                        show: this._2rbcSlots,
                        totalAppointments: this._2rbcSlots.length,
                        defaultSlots: this.driveShift.default2rbcSlots,
                        slotsAboveDefault: this._2rbcSlots.length - this.driveShift.default2rbcSlots,
                        class: classNames('slds-has-dividers_around-space appointment-slots power-red')
                    }
                );
            }
        }

        return result;
    }

    get showAppointmentForm() {
        return !!this.selectedSlot;
    }

    get disableSave() {
        return this.showAppointmentForm ? !this.showUiInputErrors() : true;
    }

    @track appointmentFormMode = 'create';
    get appointmentFormHeader() {
        if(this.appointmentFormMode === 'create') {
            return 'New Appointment';
        } else {
            return 'Edit Appointment';
        }
    }

    @api
    set masterDataDetails(input) {
        this.masterData = input;
    }
    get masterDataDetails() {
        return this.masterData;
    }

    connectedCallback() {
        registerListener('closeShiftSlotsModal', this.handleCloseAppointmentModal, this);
    }
    
    disconnectedCallback() {
        unregisterAllListeners(true);
    }

    findSlotByKey(slotKey) {
        return find(this.slotsData, item => item.key === slotKey);
    }

    handleOnChange(event) {
        let targetName = event.target.name;
        let targetValue = getValueFromEvent(event);
        this.selectedSlot[targetName] = targetValue;
    }
    
    showUiInputErrors() {
        const allValid = [...this.template.querySelectorAll('lightning-input'), ...this.template.querySelectorAll('lightning-combobox')]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);
        return allValid;
    }

    resetAppointments() {
        const _event = {
            detail: {
                driveShift: this.driveShift
            },
            bubbles: true,
            composed: true
        };

        let eventValues = {action: "resetShiftSlots", ..._event};
        fireEvent(this.pageRef, 'openDriveShiftConfirmModal', eventValues);
    }

    lockAppointments() {
        if(this.allowToInputLockReason) {
            this.showLockAppointmentModal();
            return;
        };
        
        this.selectedSlots.forEach(slot => {
            this.lockAppointment({
                slotKey: slot.key,
                fixedSiteLockComment: '',
                fixedSiteLockReason: ''
            })
        });
    }

    unlockAppointments() {
        this.selectedSlots.forEach(slot => {
            this.unlockAppointment({
                currentTarget: {
                    dataset: {
                        value: slot.key
                    }
                }
            })
        });
    }

    regenerateAppointments() {
        const _event = {
            detail: {
                driveShift: this.driveShift
            },
            bubbles: true,
            composed: true
        };

        let eventValues = {action: "regenerateShiftSlots", ..._event};
        fireEvent(this.pageRef, 'openDriveShiftConfirmModal', eventValues);
    }
    
    unlockAppointment(event) {
        const slotKey = event.currentTarget.dataset['value'];
        const slot = this.findSlotByKey(slotKey);
        if(!slot) return;
        const _event = new CustomEvent('saveappointment', {
            detail: {
                driveShift: this.driveShift,
                slotKey: slotKey,
                newSlot: {
                    key: slotKey,
                    locked: false,
                    selected: false,
                    fixedSiteLockReason: '',
                    fixedSiteLockComment: ''
                }
            },
            bubbles: true,
            composed: true
        });

        this.dispatchEvent(_event);
    }

    lockAppointment({
        slotKey,
        fixedSiteLockComment,
        fixedSiteLockReason
    }) {
        const slot = this.findSlotByKey(slotKey);
        if(!slot) return;
        const _event = new CustomEvent('saveappointment', {
            detail: {
                driveShift: this.driveShift,
                slotKey: slotKey,
                newSlot: {
                    key: slotKey,
                    locked: true,
                    selected: false,
                    fixedSiteLockReason,
                    fixedSiteLockComment
                }
            },
            bubbles: true,
            composed: true
        });

        this.dispatchEvent(_event);
    }

    addAppointment(event, defaultSlotType = SLOT_TYPE._2RBC) {
        let slotType;
        if(event) {
            slotType = event.currentTarget.dataset['value'];
        } else {
            slotType = defaultSlotType;
        }

        let newSlot = {
            key: generateUUID(),
            label: '',
            startTime: null,
            locked: false,
            slotType: slotType
        }

        this.appointmentFormMode = 'create';
        this.selectedSlot = newSlot;
        fireEvent(this.pageRef, 'openShiftSlotsModal',{
            appointmentFormMode: this.appointmentFormMode, 
            newSlot,
            driveShift: this.driveShift,
        });
    }

    editAppointment(event) {
        const slotKey = event.currentTarget.dataset['value'];
        const slot = this.findSlotByKey(slotKey);
        if(!slot) return;

        this.appointmentFormMode = 'edit';
        this.selectedSlot = cloneDeep(slot);
        fireEvent(this.pageRef, 'openShiftSlotsModal',{
            appointmentFormMode: this.appointmentFormMode, 
            newSlot: slot,
            driveShift: this.driveShift,
        });
    }

    handleSelectSlot(event) {
        const slotKey = event.currentTarget.dataset['value'];
        const slot = this.findSlotByKey(slotKey);
        if(!slot) return;

        const _event = new CustomEvent('saveappointment', {
            detail: {
                driveShift: this.driveShift,
                slotKey: slotKey,
                newSlot: {
                    key: slotKey,
                    selected: !slot.selected
                }
            },
            bubbles: true,
            composed: true
        });

        this.dispatchEvent(_event);
    }
    
    deleteAppointment(event) {
        const slotKey = event.currentTarget.dataset['value'];
        const slot = this.findSlotByKey(slotKey);
        if(!slot) return;

        this.appointmentFormMode = 'delete';
        this.selectedSlot = cloneDeep(slot);
        fireEvent(this.pageRef, 'openShiftSlotsModal',{
            action: 'delete',
            appointmentFormMode: this.appointmentFormMode, 
            newSlot: slot,
            driveShift: this.driveShift,
        });
        // const slotKey = event.currentTarget.dataset['value'];
        // const _event =  {
        //     detail: {
        //         driveShift: this.driveShift,
        //         slotKey: slotKey
        //     },
        //     bubbles: true,
        //     composed: true
        // };

        // let eventValues = {action: "deleteShiftSlotConfirm", ..._event
        // };
        // fireEvent(this.pageRef, 'openDriveShiftConfirmModal', eventValues);
    }
    
    handleCloseAppointmentModal() {
        this.selectedSlot = null;
    }
    get disableActionButton(){
        if (this.isFixedSiteDrive && this.masterData && this.masterData.loginUser 
                && (this.masterData.loginUser.profileName === 'DRD Manager' || this.masterData.loginUser.profileName === 'DRD Profile')) {
                    return true;
        }
        return false;
    }

    showLockAppointmentModal(event) {
        const slotKey = event?.currentTarget?.dataset?.['value'];
        const slot = this.findSlotByKey(slotKey);
        if(!this.allowToInputLockReason) {
            this.lockAppointment({
                slotKey,
                fixedSiteLockComment: '',
                fixedSiteLockReason: ''
            })
            return;
        }

        this.lockAppointmentModalData = {
            isOpen: true,
            slots: slot ? [slot] : this.selectedSlots,
            slotKey
        }
    }

    closeLockAppointmentModal() {
        this.lockAppointmentModalData = {};
    }

    saveLockAppointmentModal(event) {
        const { fixedSiteLockComment, fixedSiteLockReason } = event.detail;
        if(!this.lockAppointmentModalData.slotKey) {
            this.selectedSlots.forEach(slot => {
                this.lockAppointment({
                    slotKey: slot.key,
                    fixedSiteLockComment,
                    fixedSiteLockReason
                })
            });
        } else {
            this.lockAppointment({
                slotKey: this.lockAppointmentModalData.slotKey,
                fixedSiteLockComment,
                fixedSiteLockReason
            })
        }
        this.closeLockAppointmentModal();
    }
}