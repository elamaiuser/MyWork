import { LightningElement, api, track } from 'lwc';
import * as slwcUtils from 'c/slwcUtils';

export default class SlwcDriveStaffingReasonModal extends LightningElement {
    @api isOpen = false;

    /**
     * Public API method to open the modal
     */
    @api
    open() {
        this.isOpen = true;
    }

    /**
     * Public API method to close the modal
     */
    @api
    close() {
        this.closeModal();
    }

    @track selectedStaffingReason;
    @track errorMessages = [];

    /**
     * Determine if continue button should be disabled
     */
    get disabledContinue() {
        return !this.selectedStaffingReason;
    }

    /**
     * Handle staffing reason picklist change
     */
    handleOnChange(event) {
        this.selectedStaffingReason = slwcUtils.getValueFromEvent(event);
        // Clear any error messages when a value is selected
        this.errorMessages = [];
    }

    /**
     * Handle cancel button click
     * Closes the modal and dispatches cancel event
     */
    handleCancel() {
        this.closeModal();
        // Dispatch cancel event
        this.dispatchEvent(new CustomEvent('cancel'));
    }

    /**
     * Handle continue button click
     * Validates selection and dispatches event with selected value
     */
    handleContinue() {
        // Validate that a staffing reason is selected
        if (!this.selectedStaffingReason) {
            this.errorMessages = [{
                message: 'Please select a Staffing Reason.'
            }];
            return;
        }

        // Dispatch custom event with selected value
        this.dispatchEvent(new CustomEvent('staffingreasonselected', {
            detail: {
                staffingReason: this.selectedStaffingReason
            }
        }));

        // Close the modal
        this.closeModal();
    }

    /**
     * Close modal and reset state
     */
    closeModal() {
        this.isOpen = false;
        this.selectedStaffingReason = null;
        this.errorMessages = [];
    }
}