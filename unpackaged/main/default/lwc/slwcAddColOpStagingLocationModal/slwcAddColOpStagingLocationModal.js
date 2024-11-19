import { LightningElement, api } from 'lwc';
import { getValueFromEvent, isNullOrEmpty} from "c/slwcUtils";

export default class SlwcAddColOpStagingLocationModal extends LightningElement {

    @api action;
    @api collectionOperationName;
    @api model = {
        id: null,
        stagingLocation: null,
        collectionOperation: this.recordId,
        startDate: null,
        endDate: null
    };

    _isOpen = false;
    @api
    get isOpen() {
        return this._isOpen;
    }
    set isOpen(value) {
        this._isOpen = value;
    }

    _isDeleteModal = false;
    @api
    get isDeleteModal() {
        return this._isDeleteModal;
    }
    set isDeleteModal(value) {
        this._isDeleteModal = value;
    }

    _recordId;
    @api
    get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        this._recordId = value;
    }

    _disabled = true;
    get disabled() {
        return this._disabled;
    }
    set disabled(value) {
        this._disabled = value;
    }

    get modalPopUpHeader() {
        switch (this.action) {
            case "create":
                return "New Collection Operation Staging Location";
            case "edit":
                return "Edit Collection Operation Staging Location";
            case "delete":
                return "Delete Collection Operation Staging Location";
        }
    }

    handleOnChange(event) {
        event.stopPropagation();
        let value = getValueFromEvent(event);
        if (event.detail && event.detail.selection) {
            this.model[event.currentTarget.name] = event.detail.selection;
        } else {
            this.model = Object.assign({}, this.model, { [event.currentTarget.name]: value });
        }
        this.disabled = this.validateModalEntry(this.model);
    }

    handleCloseOrCancelButton() {
        this.isOpen = false;
        const closeEvent = new CustomEvent("close", {
            detail: this.isOpen
        });
        this.dispatchEvent(closeEvent);
    }

    handleSaveButtonOnModal() {
        let newRecord = {
            ...this.model,
            stagingLocationName: this.model.stagingLocation?.name,
            stagingLocationUrl: '/' + this.model.stagingLocation?.id,
            stagingLocationAddress: this.model.stagingLocation?.address
        };
        const modalDataChangeEvent = new CustomEvent("modaldatachange", {
            detail: {
                modalAction: this.action,
                newRecordFromModal: newRecord
            }
        });
        this.dispatchEvent(modalDataChangeEvent);
    }

    validateModalEntry(record) {
        return (isNullOrEmpty(record.startDate) || isNullOrEmpty(record.endDate) || isNullOrEmpty(record.stagingLocation?.id));
    }

}