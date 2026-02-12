import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class TravelTimePoc extends LightningElement {
    @track isEditing = false;
    @track viewData = [];
    @track draftData = [];
    
    // Configuration Constraints
    maxSlots = 6; 
    minDurationMs = 3600000; // 1 Hour
    maxDurationMs = 36000000; // 10 Hours

    // Updated columns to point to the formatted 12h values
    viewColumns = [
        { label: 'Label', fieldName: 'label' },
        { label: 'Start Time', fieldName: 'formattedStart' }, // Changed to formatted version
        { label: 'End Time', fieldName: 'formattedEnd' },     // Changed to formatted version
        { label: 'Duration', fieldName: 'durationDisplay' }
    ];

    connectedCallback() {
        this.viewData = this.generateMockData();
    }

    // --- MOCK DATA GENERATOR ---
    generateMockData() {
        // Initial data needs to be run through the formatter to look right in Read Mode
        const rawData = [
            { id: 1, label: 'Morning Shift', startTime: '00:00:00.000', endTime: '08:00:00.000' },
            { id: 2, label: 'Day Shift', startTime: '08:00:00.000', endTime: '16:00:00.000' },
            { id: 3, label: 'Night Shift', startTime: '16:00:00.000', endTime: '23:59:00.000' }
        ];

        // Process the raw data to add the formatted strings and durations
        return rawData.map((slot, index) => {
             return this.processSlotMetrics(slot, index, rawData.length);
        });
    }

    handleEdit() {
        this.draftData = JSON.parse(JSON.stringify(this.viewData));
        this.recalculateLogic(); 
        this.isEditing = true;
    }

    handleCancel() {
        this.isEditing = false;
        this.draftData = [];
    }

    handleInputChange(event) {
        const index = event.target.dataset.index;
        const field = event.target.dataset.field;
        this.draftData[index][field] = event.detail.value;
    }

    handleTimeChange(event) {
        const index = parseInt(event.target.dataset.index, 10);
        let newVal = event.detail.value;
        if(newVal && newVal.length === 5) newVal += ':00.000'; 

        this.draftData[index].endTime = newVal;

        // Update next row's start time
        if (index < this.draftData.length - 1) {
            this.draftData[index + 1].startTime = newVal;
        }

        this.recalculateLogic();
    }

    handleAddSlot() {
        if (this.draftData.length >= this.maxSlots) return;

        let lastSlot = this.draftData[this.draftData.length - 1];
        
        let startMs = this.timeToMs(lastSlot.startTime);
        // Default Add 2 hours at split
        let newSplitMs = startMs + 7200000; 
        
        // Update current last slot to end at split
        lastSlot.endTime = this.msToTime24h(newSplitMs);

        // Create new slot
        let newSlot = {
            id: Date.now(), 
            label: 'New Slot',
            startTime: lastSlot.endTime,
            endTime: '23:59:00.000'
        };

        this.draftData.push(newSlot);
        this.recalculateLogic();
    }

    handleDeleteRow(event) {
        const index = parseInt(event.target.dataset.index, 10);
        
        if (index > 0) {
            let prevSlot = this.draftData[index - 1];
            let deletedSlot = this.draftData[index];
            prevSlot.endTime = deletedSlot.endTime; // Merge
            this.draftData.splice(index, 1);
            
            if (index < this.draftData.length) {
                this.draftData[index].startTime = prevSlot.endTime;
            }
        } else {
            this.draftData.splice(0, 1);
            this.draftData[0].startTime = '00:00:00.000';
        }
        
        this.recalculateLogic();
    }

    handleSave() {
        if(this.hasErrors) return;
        this.viewData = JSON.parse(JSON.stringify(this.draftData));
        this.isEditing = false;
        
        this.dispatchEvent(new ShowToastEvent({
            title: 'Success',
            message: 'Master Schedule saved (Mon-Sun).',
            variant: 'success'
        }));
    }

    // --- CALCULATIONS & VALIDATION ---

    recalculateLogic() {
        this.draftData = this.draftData.map((slot, index) => {
            return this.processSlotMetrics(slot, index, this.draftData.length);
        });
    }

    // Unified logic helper for both View and Edit modes
    processSlotMetrics(slot, index, totalLength) {
        const isLast = index === totalLength - 1;
        
        // Enforce Boundaries
        if(index === 0) slot.startTime = '00:00:00.000';
        if(isLast) slot.endTime = '23:59:00.000';

        // Calc Duration
        let startMs = this.timeToMs(slot.startTime);
        let endMs = this.timeToMs(slot.endTime);
        
        if(slot.endTime.startsWith('23:59')) endMs = 86400000; // 24 hours

        let diff = endMs - startMs;
        let isValid = true;
        let errorMsg = '';

        if(diff < this.minDurationMs) {
            isValid = false; 
            errorMsg = 'Min 1 hour';
        } else if (diff > this.maxDurationMs) {
            isValid = false;
            errorMsg = 'Max 10 hours';
        }

        return {
            ...slot,
            indexDisplay: index + 1,
            isLastRow: isLast,            
            formattedStart: this.msToTime12h(startMs),
            formattedEnd: this.msToTime12h(endMs),
            
            durationDisplay: (diff / 3600000).toFixed(1) + ' hrs',
            durationIcon: isValid ? 'utility:clock' : 'utility:warning',
            badgeClass: isValid ? 'slds-theme_success' : 'slds-theme_error',
            validationClass: isValid ? '' : 'slds-has-error',
            hasError: !isValid,
            errorMsg: errorMsg
        };
    }

    // --- HELPERS ---

    timeToMs(timeStr) {
        if(!timeStr) return 0;
        let parts = timeStr.split(':');
        return (parseInt(parts[0], 10) * 3600000) + (parseInt(parts[1], 10) * 60000);
    }

    // Converts MS back to HH:mm:ss.000 for the system values
    msToTime24h(duration) {
        let hours = Math.floor(duration / 3600000);
        let minutes = Math.floor((duration % 3600000) / 60000);
        return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:00.000`;
    }

    // NEW: Converts MS to "8:00 AM" format for Display
    msToTime12h(duration) {
        // Handle 24h/Midnight edge case
        if (duration >= 86400000 - 60000) return '11:59 PM'; // Handle 23:59 specifically
        if (duration >= 86400000) return '12:00 AM'; // Next day midnight

        let totalMins = Math.floor(duration / 60000);
        let hours = Math.floor(totalMins / 60);
        let mins = totalMins % 60;
        
        let ampm = hours >= 12 ? 'PM' : 'AM';
        
        hours = hours % 12;
        hours = hours ? hours : 12; // the hour '0' should be '12'
        
        let strMin = mins < 10 ? '0' + mins : mins;
        
        return `${hours}:${strMin} ${ampm}`;
    }

    get hasErrors() { return this.draftData.some(d => d.hasError); }
    get disableAddButton() { return this.draftData.length >= this.maxSlots; }
    get isSingleRow() { return this.draftData.length <= 1; }
    get limitTextClass() { return this.disableAddButton ? 'slds-text-color_error' : 'slds-text-color_weak'; }
}