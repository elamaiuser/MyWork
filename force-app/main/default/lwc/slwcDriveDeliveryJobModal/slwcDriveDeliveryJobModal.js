import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { fireEvent, registerListener, unregisterAllListeners } from 'c/pubsub';
import * as slwcUtils from 'c/slwcUtils';
import { DRIVE_DELIVERY_JOBS_TYPE, DRIVE_BAG_TYPE } from 'c/slwcConstants';
import { uniqueId,remove,isNull, cloneDeep } from 'c/lodash';

export default class SlwcDriveDeliveryJobModal extends LightningElement {
    @api drive;

    @track driveDeliveryJobs = {
        driveBags: []
    };
    @track messages = []
    @track showModal = false;
    @track action;
    @track modalHeader;
    @track bagType;
    @track quantity;
    @track ltowbProjection;
    @track ltowbProjHasError = false;
    @track dirty = false;
    @track isDeleteForm;
    @track actionOptions = [];
    @wire(CurrentPageReference) pageRef;

    connectedCallback() {
        registerListener('showDriveDeliveryJobModal', this.handleShowDriveDeliveryJobModal, this);
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    get showButtonAdd(){
        if (!this.bagType || !this.quantity) return false;
        if (this.showLtowbProj && this.ltowbProjHasError) return false;
        return true;
    }

    get isMobile(){
        // return true
        return slwcUtils.isMobile()
    }

    get showBagSection() {
        return this.driveDeliveryJobs.type == DRIVE_DELIVERY_JOBS_TYPE.BAG;
    }

    get showLtowbProj() {
        return this.bagType === DRIVE_BAG_TYPE.IM_TERUMO_IMUFLEX_WB;
    }

    get showTimeSection() {
        return this.driveDeliveryJobs.type != DRIVE_DELIVERY_JOBS_TYPE.BAG;
    }

    get isPickUpRequired() {
        return this.driveDeliveryJobs.type == DRIVE_DELIVERY_JOBS_TYPE.VOL_PICK_UP;
    }

    /** Custom functions **/
    closeModal() {
        fireEvent(this.pageRef, 'closeDriveDeliveryJobModal');
        this.showModal = false;
    }

    validate(){
        this.messages = []
        const isAllInputValid = [...this.template.querySelectorAll('lightning-input'), ...this.template.querySelectorAll('lightning-combobox')]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);
        this.dirty = true;
        if(this.driveDeliveryJobs.type == DRIVE_DELIVERY_JOBS_TYPE.BAG && (!this.driveDeliveryJobs.driveBags || this.driveDeliveryJobs.driveBags && this.driveDeliveryJobs.driveBags.length == 0)){
            this.messages.push("Please add bags");
        }
        if(this.driveDeliveryJobs.driveBags) {
            this.driveDeliveryJobs.driveBags.forEach(bag => {
                if(bag.bagType === DRIVE_BAG_TYPE.IM_TERUMO_IMUFLEX_WB && bag.ltowbProjection != null && (!Number.isInteger(bag.ltowbProjection) || bag.ltowbProjection < 0)) {
                    this.messages.push("LTOWB Proj must be a non-negative integer");
                }
            });
        }
        if(this.driveDeliveryJobs.start && this.driveDeliveryJobs.end && this.driveDeliveryJobs.start >= this.driveDeliveryJobs.end){
            this.messages.push("End should be greater than Start");
        }
        if(this.driveDeliveryJobs.pickUp && this.driveDeliveryJobs.arrive && this.driveDeliveryJobs.pickUp >= this.driveDeliveryJobs.arrive){
            this.messages.push("Arrive should be greater than Pick Up");
        }
        return !isAllInputValid || this.messages.length;
    }

    handleDelete = (confirm) => {
        if(confirm) {
            let eventValues = {action: this.action, driveDeliveryJobs: this.driveDeliveryJobs};
            fireEvent(this.pageRef, 'deleteDriveDeliveryJob', eventValues);
        }
        this.closeModal();
    }

    handleOnChange(event) {
        let targetName = event.target.name;
        let targetValue = slwcUtils.getValueFromEvent(event);
        this.driveDeliveryJobs[targetName] = targetValue
        console.log("this.driveDeliveryJobs", this.driveDeliveryJobs);
    }

    handleOnChangeBag(event) {
        let targetName = event.target.name;

        if (targetName === 'ltowbProjection') {
            this.validateAndSetLtowb(event.target);
            return;
        }

        let targetValue = slwcUtils.getValueFromEvent(event);
        this[targetName] = targetValue;

        if (targetName === 'bagType' && targetValue !== DRIVE_BAG_TYPE.IM_TERUMO_IMUFLEX_WB) {
            this.ltowbProjection = null;
            this.ltowbProjHasError = false;
        }

        console.log("this.driveDeliveryJobs", this.driveDeliveryJobs);
    }

    validateAndSetLtowb(inputEl) {
        const rawValue = inputEl.value;

        if (!rawValue || rawValue.trim() === '') {
            this.ltowbProjection = null;
            this.ltowbProjHasError = false;
        } else if (/^\d+$/.test(rawValue.trim())) {
            this.ltowbProjection = parseInt(rawValue.trim(), 10);
            this.ltowbProjHasError = false;
        } else {
            this.ltowbProjection = null;
            this.ltowbProjHasError = true;
        }

        inputEl.setCustomValidity(this.ltowbProjHasError ? ' ' : '');
        inputEl.reportValidity();
    }

    handleAdd() {
        if (this.bagType && this.quantity) {
            if (this.showLtowbProj) {
                const ltowbInput = this.template.querySelector('lightning-input[name="ltowbProjection"]');
                if (ltowbInput) {
                    // Re-validate at click time to catch cases where onchange hasn't fired yet
                    this.validateAndSetLtowb(ltowbInput);
                    if (this.ltowbProjHasError) return;
                }
            }

            const newBag = {
                bagType: this.bagType,
                quantity: this.quantity,
                key: uniqueId("bag_")
            };

            if (this.bagType === DRIVE_BAG_TYPE.IM_TERUMO_IMUFLEX_WB) {
                newBag.ltowbProjection = this.ltowbProjection != null ? this.ltowbProjection : null;
            }

            if (this.driveDeliveryJobs["driveBags"]) {
                this.driveDeliveryJobs["driveBags"].push(newBag);
            } else {
                this.driveDeliveryJobs["driveBags"] = [newBag];
            }

            this.quantity = null;
            this.bagType = null;
            this.ltowbProjection = null;
            this.ltowbProjHasError = false;
        }
    }

    handleDeleteBag(event){
        const {key} = event.currentTarget.dataset;
        remove(this.driveDeliveryJobs["driveBags"], item => item.key == key)
    }

    handleShowDriveDeliveryJobModal(detail) {
        this.action = detail.action;
        switch(this.action) {
            case "create":
                this.modalHeader = "New Drive Delivery Job";
                this.driveDeliveryJobs = {key: Math.random().toString(36).substring(2, 15)};
                this.isDeleteForm = false;
                break;
            case "edit":
                this.modalHeader = "Update Drive Delivery Job";
                this.driveDeliveryJobs = cloneDeep(detail.driveDeliveryJobs);
                this.isDeleteForm = false;
                break;
            case "delete":
                this.modalHeader = "Delete Drive Delivery Job";
                this.driveDeliveryJobs = cloneDeep(detail.driveDeliveryJobs);
                this.isDeleteForm = true;
                break;
        }
        this.messages = [];
        this.ltowbProjection = null;
        this.ltowbProjHasError = false;
        this.showModal = true;
    }

    handleSave() {
        const hasError = this.validate()
        if(hasError){
            return
        }
        let eventValues = {action: this.action, driveDeliveryJobs: this.driveDeliveryJobs};
        fireEvent(this.pageRef, 'saveDriveDeliveryJob', eventValues);
        this.closeModal();
    }

    handleSelectContact(event) {
        if (event.detail && event.detail.selection) {
            this.driveDeliveryJobs.contact = event.detail.selection;
            this.driveDeliveryJobs.contactId = event.detail.selection.id;
        }
    }
}