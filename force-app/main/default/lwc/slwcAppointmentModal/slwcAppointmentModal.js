import { LightningElement,track,wire,api } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { fireEvent,registerListener } from 'c/pubsub';
import { getValueFromEvent, generateUUID } from 'c/slwcUtils';
import { SLOT_TYPE } from 'c/slwcConstants';
import { cloneDeep } from 'c/lodash';
import { DateTime } from 'c/luxon';
import { DriveHelper } from 'c/slwcDriveGenerator';

export default class SlwcAppointmentModal extends LightningElement {
    driveHelper = new DriveHelper();

    @track showModal = false;
    @track appointmentFormMode = 'create'
    @track selectedSlot;
    @track driveShift;
    @track startTimeOptions = {};
    @track recurrenceDatesPickerModalData = {};
    @track errorMessages = [];
    
    @wire(CurrentPageReference) pageRef;

    get appointmentFormHeader() {
        if(this.appointmentFormMode === 'create') {
            return 'New Appointment';
        } else if (this.appointmentFormMode === 'edit') {
            return 'Edit Appointment';
        } else if (this.appointmentFormMode === 'delete') {
            return 'Delete Appointment';
        }
    }

    get isDeleteMode() {
        return this.appointmentFormMode === 'delete';
    }

    get showApplyFutureDatesBtn() {
        const isLinkedDrive = this.drive.linkedDriveId;
        return (
            this.driveHelper.isFixedSiteDrive(this.drive) ||
            this.driveHelper.isWbFixedSiteDrive(this.drive)
        ) && !isLinkedDrive;
    }

    get saveButtonLabel() {
        if(this.appointmentFormMode === 'delete') {
            return 'Yes';
        } else {
            return 'Save';
        }
    }

    @api drive;
    @api masterData;
    @api compactView = false;
    
    connectedCallback() {
        registerListener('openShiftSlotsModal', this.handleShowAppointmentModal, this);
    }
    
    convertJSDateToTimeISO(dateJS) {
        if(!dateJS) return null;
        return DateTime.fromJSDate(dateJS, {
            zone: this.masterData.timezoneSidId
        }).toFormat('HH:mm:ss.000');
    }

    handleShowAppointmentModal(event) {
        console.log("handleShowAppointmentModal", event);
        this.appointmentFormMode = event.appointmentFormMode;
        this.selectedSlot = cloneDeep(event.newSlot);
        this.selectedSlot["_startTime"] =  this.selectedSlot.startTime ? this.convertJSDateToTimeISO(new Date(this.selectedSlot.startTime)) : null;
        this.driveShift = event.driveShift;
        this.showModal = true;
        if(!this.selectedSlot.recurrenceDates) {
            this.selectedSlot.recurrenceDates = [];
        }
        if(!this.selectedSlot.recurrenceDriveIds) {
            this.selectedSlot.recurrenceDriveIds = [];
        }
        if(this.appointmentFormMode === 'create') {
            this.selectedSlot.quantity = 1;
        }
        this.setupStartTimeMinMaxTime();
    }

    handleOnChange(event) {
        let targetName = event.target.name;
        let targetValue = getValueFromEvent(event);
        this.selectedSlot[targetName] = targetValue;
    }

    cancelAppointmentForm() {
        this.showModal = false;
        fireEvent(this.pageRef, 'closeShiftSlotsModal',{});
    }
    
    setupStartTimeMinMaxTime() {
        const selectedSlot = this.selectedSlot;
        this.startTimeOptions.min = this.driveShift.startTime;
        this.startTimeOptions.max = this.driveShift.endTime;

        if(!selectedSlot) return;

        if(selectedSlot.slotType === SLOT_TYPE.WB) {
            //max start = 15 mins before shift end time
            let maxEndTime = this.convertTimeISOToJSDate(this.driveShift.driveDate, this.driveShift.endTime).getTime() - 15 * 60000;
            this.startTimeOptions.max = this.convertJSDateToTimeISO(new Date(maxEndTime));
        } else if (selectedSlot.slotType === SLOT_TYPE._2RBC) {
            //max start = 30 mins before shift end time
            let maxEndTime = this.convertTimeISOToJSDate(this.driveShift.driveDate, this.driveShift.endTime).getTime() - 30 * 60000;
            this.startTimeOptions.max = this.convertJSDateToTimeISO(new Date(maxEndTime));
        }
    }

    validate() {
        this.errorMessages = [];
        
        const allValid = [...this.template.querySelectorAll('lightning-input'), ...this.template.querySelectorAll('lightning-combobox')]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);

        if(this.appointmentFormMode === 'create') {
            if(!this.selectedSlot.quantity ||
                this.selectedSlot.quantity <= 0
            ) {
                this.errorMessages.push({
                    message: `The quantity must be greater than 0`
                }) 
            }
        }
        
        return allValid && !this.errorMessages.length;
    }

    convertTimeISOToJSDate(dateISO, timeISO) {
        let dateTimeIso = dateISO + 'T' + timeISO;
        let date = new Date(dateTimeIso);
            
        var invdate = new Date(date.toLocaleString('en-US', {
            timeZone: this.masterData.timezoneSidId
        }));
            
        var diff = date.getTime() - invdate.getTime();
          
        return new Date(date.getTime() + diff);
    }
    saveAppointmentForm() {
        if(!this.validate()) return;

        const newSlot = {...this.selectedSlot, 
            startTime: this.convertTimeISOToJSDate(this.driveShift.driveDate, this.selectedSlot._startTime).toISOString(),
        };

        const _event = new CustomEvent('saveappointment', {
            detail: {
                action: this.appointmentFormMode,
                driveShift: this.driveShift,
                slotKey: this.selectedSlot.key,
                newSlot: newSlot
            },
            bubbles: true,
            composed: true
        });
        this.dispatchEvent(_event);      
        this.selectedSlot = null;  
        this.cancelAppointmentForm();
    }

    /* Recurrence Dates Picker modal */
    openRecurrenceDatesPickerModalData() {
        this.recurrenceDatesPickerModalData = {
            isOpen: true,
            selectedDays: this.selectedSlot.recurrenceDates,
            selectedDriveIds: this.selectedSlot.recurrenceDriveIds
        }
    }

    saveRecurrenceDatesPickerModalData(event) {
        const { selectedDays, selectedDriveIds } = event.detail; 
        this.selectedSlot.recurrenceDates = selectedDays;
        this.selectedSlot.recurrenceDriveIds = selectedDriveIds
    }

    closeRecurrenceDatesPickerModalData() {
        this.recurrenceDatesPickerModalData = {};
    }
}