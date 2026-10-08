import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { RefreshEvent } from 'lightning/refresh';
import getInitialData from '@salesforce/apex/DriveMovementController.getInitialData';
import searchSites from '@salesforce/apex/DriveMovementController.searchSites';
import saveMovements from '@salesforce/apex/DriveMovementController.saveMovements';
import finalizeMovements from '@salesforce/apex/DriveMovementController.finalizeMovements'; 
import withdrawMovements from '@salesforce/apex/DriveMovementController.withdrawMovements';

export default class DriveMovementManager extends LightningElement {
    @api recordId;
    @api parentRecordId;
    @api objectApiName;
    @api actionType; 
    
    @track movements = [];
    @track hasUnsavedChanges = false;
    isLoading = true;
    originalState = ''; 
    
    siteTypeOptions = [
        { label: 'Blood Drive Site', value: 'Blood Drive Site' },
        { label: 'TMS Site', value: 'TMS Site' }
    ];

    get isGlobalReadOnly() {
        return this.movements && this.movements.length > 0 && this.movements[0].isReadOnly;
    }

    get isSavedRecord() {
        return this.movements && this.movements.length > 0 && this.movements[0].movementRecordId != null;
    }

    get isSaveDisabled() {
        if (!this.isSavedRecord) {
            return false; 
        }
        return !this.hasUnsavedChanges;
    }

    get isFinalRecord() {
        return this.movements && this.movements.length > 0 && this.movements[0].status === 'Final';
    }

    get isCanceledRecord() {
        return this.movements && this.movements.length > 0 && this.movements[0].status === 'Canceled';
    }

    connectedCallback() {
        this.fetchData(this.recordId, this.parentRecordId);
    }

    fetchData(rId, pId) {
        this.isLoading = true;
        getInitialData({ recordId: rId, parentRecordId: pId, actionType: this.actionType, objectApiName: this.objectApiName })
        .then(result => {
            if (result.isSuccess) {
                this.movements = JSON.parse(JSON.stringify(result.movements));
                this.movements.forEach((mov, idx) => {
                    this.evaluateCarrier(idx);
                    this.recalculateStops(idx); 
                });
                this.originalState = JSON.stringify(this.movements); 
                this.hasUnsavedChanges = false; // Reset dirty state on load
            } else {
                this.showToast('Initialization Error', result.message, 'error');
            }
        })
        .catch(err => {
            const errorMsg = err && err.body ? err.body.message : (err ? err.message : 'Unknown Error');
            this.showToast('Initialization Error', errorMsg, 'error');
        })
        .finally(() => { this.isLoading = false; });
    }

    handleDriveChange(event) {
        const driveId = event.detail.value;
        if(driveId) { this.fetchData(null, driveId); }
    }

    handleMovementChange(event) {
        this.hasUnsavedChanges = true;
        this.movements[event.target.dataset.mIndex][event.target.dataset.field] = event.target.value;
    }

    handleJobChange(event) {
        this.hasUnsavedChanges = true;
        const mIndex = event.target.dataset.mIndex;
        this.movements[mIndex].selectedJobId = event.detail.value;
        this.evaluateCarrier(mIndex);
    }

    evaluateCarrier(mIndex) {
        const mov = this.movements[mIndex];
        
        if (mov.isReadOnly) {
            mov.isCarrierDisabled = true;
            return;
        }

        if (!mov.selectedJobId || !mov.jobOptions) return;
        
        const selectedJob = mov.jobOptions.find(opt => opt.value === mov.selectedJobId);
        if (selectedJob) {
            if (selectedJob.type === 'Pick Up') {
                mov.carrier = 'Redcross Employee'; mov.isCarrierDisabled = true;
            } else if (selectedJob.type === 'VOL Pick Up') {
                mov.carrier = 'Volunteer'; mov.isCarrierDisabled = true;
            } else {
                mov.carrier = ''; mov.isCarrierDisabled = false;
            }

            if (!mov.movementRecordId && selectedJob.pickupTime && mov.stops && mov.stops.length > 0) {
                let firstStop = mov.stops[0];
                firstStop.departStartStr = selectedJob.pickupTime;
                firstStop.departEndStr = this.addMins(selectedJob.pickupTime, 30);
            }
        }
    }

    handleRoundTripToggle(event) {
        this.hasUnsavedChanges = true;
        const mIndex = event.target.dataset.mIndex;
        const mov = this.movements[mIndex];
        mov.isRoundTrip = event.target.checked;
        
        if (!mov.isRoundTrip) {
            mov.stops.pop();
        } else {
            let firstStop = mov.stops[0];
            let newStop = { ...firstStop };
            newStop.departStartStr = null; newStop.departEndStr = null;
            newStop.arriveStartStr = null; newStop.arriveEndStr = null;
            mov.stops.push(newStop);
        }
        this.recalculateStops(mIndex);
    }

    handleStopTypeChange(event) {
        this.hasUnsavedChanges = true;
        const mIndex = parseInt(event.target.dataset.mIndex, 10);
        const sIndex = parseInt(event.target.dataset.sIndex, 10);
        const stop = this.movements[mIndex].stops[sIndex];
        
        stop.siteType = event.detail.value;
        stop.siteId = ''; stop.siteName = ''; stop.showDropdown = false;
        
        this.mirrorFirstStopToLast(mIndex);
        this.movements = [...this.movements];
    }

    showDefaultSiteOptions(mIndex, sIndex) {
        const mov = this.movements[mIndex];
        const stop = mov.stops[sIndex];

        if (stop.siteType === 'Blood Drive Site' && mov.driveSiteId) {
            stop.siteSearchResults = [{ label: mov.driveSiteName, value: mov.driveSiteId }];
            stop.showDropdown = true;
        } else if (stop.siteType === 'TMS Site' && mov.assignedTmsSites && mov.assignedTmsSites.length > 0) {
            stop.siteSearchResults = mov.assignedTmsSites;
            stop.showDropdown = true;
        } else {
            stop.siteSearchResults = [];
            stop.showDropdown = false;
        }
        this.movements = [...this.movements];
    }

    handleSiteFocus(event) {
        const mIndex = parseInt(event.target.dataset.mIndex, 10);
        const sIndex = parseInt(event.target.dataset.sIndex, 10);
        const stop = this.movements[mIndex].stops[sIndex];
        if (!stop.siteName || stop.siteName.length < 3) {
            this.showDefaultSiteOptions(mIndex, sIndex);
        }
    }

    searchTimeout;
    handleSiteSearch(event) {
        const mIndex = parseInt(event.target.dataset.mIndex, 10);
        const sIndex = parseInt(event.target.dataset.sIndex, 10);
        const term = event.target.value;
        const stop = this.movements[mIndex].stops[sIndex];
        
        stop.siteName = term;

        if (term && term.length >= 3) {
            if (this.searchTimeout) { clearTimeout(this.searchTimeout); }
            this.searchTimeout = setTimeout(() => {
                searchSites({ searchTerm: term, siteType: stop.siteType })
                    .then(res => {
                        stop.siteSearchResults = res;
                        stop.showDropdown = res.length > 0;
                        this.movements = [...this.movements];
                    })
                    .catch(err => {
                        const errorMsg = err && err.body ? err.body.message : 'Search failed.';
                        this.showToast('Search Error', errorMsg, 'error');
                        stop.showDropdown = false;
                        this.movements = [...this.movements];
                    });
            }, 300);
        } else {
            this.showDefaultSiteOptions(mIndex, sIndex);
        }
    }

    handleSiteSelect(event) {
        this.hasUnsavedChanges = true;
        const mIndex = parseInt(event.currentTarget.dataset.mIndex, 10);
        const sIndex = parseInt(event.currentTarget.dataset.sIndex, 10);
        const stop = this.movements[mIndex].stops[sIndex];
        
        stop.siteId = event.currentTarget.dataset.id; 
        stop.siteName = event.currentTarget.dataset.name; 
        stop.showDropdown = false;
        
        this.mirrorFirstStopToLast(mIndex);
        this.movements = [...this.movements];
    }
    
    handleSiteChange(event) {
        this.hasUnsavedChanges = true;
        const mIndex = parseInt(event.target.dataset.mIndex, 10);
        const sIndex = parseInt(event.target.dataset.sIndex, 10);
        const stop = this.movements[mIndex].stops[sIndex];
        
        stop.siteName = event.target.value;

        if (!stop.siteName) {
            stop.siteId = ''; 
            this.showDefaultSiteOptions(mIndex, sIndex);
            this.mirrorFirstStopToLast(mIndex);
            this.movements = [...this.movements]; 
        }
    }

    handleSiteBlur(event) {
        const mIndex = parseInt(event.target.dataset.mIndex, 10);
        const sIndex = parseInt(event.target.dataset.sIndex, 10);
        const stop = this.movements[mIndex].stops[sIndex];
        setTimeout(() => { stop.showDropdown = false; this.movements = [...this.movements]; }, 200);
    }

    mirrorFirstStopToLast(mIndex) {
        const mov = this.movements[mIndex];
        if (mov.isRoundTrip && mov.stops.length > 1) {
            const first = mov.stops[0]; const last = mov.stops[mov.stops.length - 1];
            last.siteType = first.siteType; last.siteId = first.siteId; last.siteName = first.siteName;
        }
    }

    handleTimeChange(event) {
        this.hasUnsavedChanges = true;
        const { mIndex, sIndex, field } = event.target.dataset;
        const val = event.target.value;
        const stop = this.movements[mIndex].stops[sIndex];
        stop[field] = val;
        
        if (field === 'departStartStr' && val) stop.departEndStr = this.addMins(val, 30);
        if (field === 'arriveStartStr' && val) stop.arriveEndStr = this.addMins(val, 30);
        this.movements = [...this.movements];
    }

    addMins(timeStr, mins) {
        if (!timeStr) return null;
        let [hh, mm] = timeStr.split(':');
        let d = new Date(); d.setHours(parseInt(hh, 10)); d.setMinutes(parseInt(mm, 10) + mins);
        return `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
    }

    timeToMins(timeStr) {
        if (!timeStr) return 0;
        let [hh, mm] = timeStr.split(':');
        return parseInt(hh, 10) * 60 + parseInt(mm, 10);
    }

    handleAddStop(event) {
        this.hasUnsavedChanges = true;
        const { mIndex, sIndex } = event.target.dataset;
        const mov = this.movements[mIndex];
        mov.stops.splice(parseInt(sIndex, 10) + 1, 0, { siteType: 'TMS Site', siteId: '', siteName: '', showDropdown: false, siteSearchResults: [], isSiteDisabled: false });
        this.recalculateStops(mIndex);
    }

    handleRemoveStop(event) {
        this.hasUnsavedChanges = true;
        const { mIndex, sIndex } = event.target.dataset;
        this.movements[mIndex].stops.splice(parseInt(sIndex, 10), 1);
        this.recalculateStops(mIndex);
    }

    recalculateStops(mIndex) {
        const mov = this.movements[mIndex];
        const total = mov.stops.length;
        
        mov.stops.forEach((stop, idx) => {
            let i = idx + 1;
            stop.sequence = i;
            stop.isFirstStop = (i === 1); stop.isSecondStop = (i === 2); stop.isLastStop = (i === total);

            if (mov.isRoundTrip && stop.isLastStop) {
                stop.isSiteDisabled = true || mov.isReadOnly;
            } else {
                stop.isSiteDisabled = mov.isReadOnly;
            }

            if (mov.isRoundTrip) {
                stop.canAdd = !(stop.isFirstStop || stop.isLastStop) && !mov.isReadOnly;
                stop.canRemove = !(stop.isFirstStop || stop.isSecondStop || stop.isLastStop) && !mov.isReadOnly;
            } else {
                stop.canAdd = !stop.isFirstStop && !mov.isReadOnly;
                stop.canRemove = !(stop.isFirstStop || stop.isSecondStop) && !mov.isReadOnly;
            }
        });
        this.mirrorFirstStopToLast(mIndex);
        this.movements = [...this.movements];
    }

    validateUI() {
        let isValid = true;
        mainLoop:
        for (let i = 0; i < this.movements.length; i++) {
            let mov = this.movements[i];
            if (!mov.movementNumber || !mov.selectedJobId || !mov.carrier) {
                this.showToast('Validation Error', 'Movement Number, Delivery Job, and Carrier are mandatory.', 'error');
                isValid = false; break mainLoop;
            }
            for (let j = 0; j < mov.stops.length; j++) {
                let stop = mov.stops[j];
                let prefix = `Stop #${stop.sequence}: `;

                if (!stop.siteType || (!stop.siteId && !stop.siteName)) {
                    this.showToast('Validation Error', prefix + 'Site Type and Site Name are mandatory.', 'error');
                    isValid = false; break mainLoop;
                }
                if (!stop.isLastStop && (!stop.departStartStr || !stop.departEndStr)) {
                    this.showToast('Validation Error', prefix + 'Depart Start and End are mandatory.', 'error');
                    isValid = false; break mainLoop;
                }
                if (!stop.isLastStop && this.timeToMins(stop.departEndStr) <= this.timeToMins(stop.departStartStr)) {
                    this.showToast('Validation Error', prefix + 'Depart End must be greater than Depart Start.', 'error');
                    isValid = false; break mainLoop;
                }
                if (stop.arriveStartStr && !stop.arriveEndStr) {
                    this.showToast('Validation Error', prefix + 'Arrive End is mandatory if Arrive Start is populated.', 'error');
                    isValid = false; break mainLoop;
                }
            }
        }
        return isValid;
    }

    handleSave() {
        if (!this.validateUI()) return;
        this.isLoading = true;
        
        saveMovements({ jsonData: JSON.stringify(this.movements) })
            .then(result => {
                if (result.isSuccess) {
                    this.showToast('Success', result.message, 'success');
                    this.movements = JSON.parse(JSON.stringify(result.movements));
                    this.originalState = JSON.stringify(this.movements); 
                    this.hasUnsavedChanges = false; // Reset dirty state on save
                } else {
                    this.showToast('Error', result.message, 'error');
                }
            })
            .catch(error => {
                let errorMsg = error && error.body && error.body.message ? error.body.message : (error ? error.message : 'Unknown Error');
                this.showToast('Save Error', errorMsg, 'error');
            })
            .finally(() => { this.isLoading = false; });
    }

    handleFinalize() {
        if (this.hasUnsavedChanges) {
            this.showToast('Warning', 'Please save your changes before finalizing.', 'warning');
            return;
        }

        this.isLoading = true;
        
        finalizeMovements({ jsonData: JSON.stringify(this.movements) })
            .then(result => {
                if (result.isSuccess) {
                    this.showToast('Success', 'Record finalized successfully.', 'success');
                    this.movements = JSON.parse(JSON.stringify(result.movements));
                    this.originalState = JSON.stringify(this.movements); 
                    this.hasUnsavedChanges = false; 
                    
                } else {
                    this.showToast('Error', result.message, 'error');
                }
            })
            .catch(error => {
                let errorMsg = error && error.body && error.body.message ? error.body.message : (error ? error.message : 'Unknown Error');
                this.showToast('Finalize Error', errorMsg, 'error');
            })
            .finally(() => { this.isLoading = false; });
    }

    handleWithdraw() {
        this.isLoading = true;
        
        withdrawMovements({ jsonData: JSON.stringify(this.movements) })
            .then(result => {
                if (result.isSuccess) {
                    this.showToast('Success', 'Record withdrawn and canceled successfully.', 'success');
                    this.movements = JSON.parse(JSON.stringify(result.movements));
                    this.originalState = JSON.stringify(this.movements); 
                
                } else {
                    this.showToast('Error', result.message, 'error');
                }
            })
            .catch(error => {
                let errorMsg = error && error.body && error.body.message ? error.body.message : (error ? error.message : 'Unknown Error');
                this.showToast('Withdraw Error', errorMsg, 'error');
            })
            .finally(() => { this.isLoading = false; });
    }

    handleReset() {
        if (this.originalState) {
            this.movements = JSON.parse(this.originalState);
            this.hasUnsavedChanges = false; 
            this.showToast('Success', 'Form reset to original state', 'success');
        }
    }

    handleClose() {
        this.movements = null; 
        this.originalState = '';
        this.hasUnsavedChanges = false;
        this.isLoading = true;
        this.dispatchEvent(new RefreshEvent());
        
        try { eval("$A.get('e.force:refreshView').fire();"); } catch(e) {}

        this.dispatchEvent(new CustomEvent('close')); 
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}