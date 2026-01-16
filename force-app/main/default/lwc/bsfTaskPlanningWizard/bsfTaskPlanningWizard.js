import { LightningElement, track, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getTaskBundles from '@salesforce/apex/BSF_TaskPlanningWizardController.getTaskBundles';
import saveTaskPlans from '@salesforce/apex/BSF_TaskPlanningWizardController.saveTaskPlans';

export default class BsfTaskPlanningWizard extends LightningElement {
    @api recordId;
    @track bundleList = [];
    @track selectedPath = 'Standard';
    @track isLoading = true;
    @track showConfirmation = false;
    @track isReadOnly = false;
    
    rawBackendData = [];
    pendingPath = '';

    get pathOptions() {
        return [
            { label: 'Standard Path', value: 'Standard' },
            { label: 'Flexible Path', value: 'Flexible' }
        ];
    }

    get showBundles() { return this.bundleList.length > 0 && !this.isLoading; }

    @wire(getTaskBundles, { recordId: '$recordId' })
    wiredData({ error, data }) {
        this.isLoading = true;
        if (data) {
            this.selectedPath = data.currentPath ? data.currentPath : 'Standard';
            this.isReadOnly = (data.driveStatus === 'Confirmed');
            this.rawBackendData = JSON.parse(JSON.stringify(data.packages));
            this.computeView();
        } else if (error) {
            console.error(error);
            this.showToast('Error', 'Failed to load task packages.', 'error');
        }
        this.isLoading = false;
    }

    handlePathChangeRequest(event) {
        this.pendingPath = event.detail.value;
        this.showConfirmation = true;
    }

    confirmPathChange() {
        this.selectedPath = this.pendingPath;
        this.showConfirmation = false;
        this.computeView();
    }

    cancelPathChange() {
        this.showConfirmation = false;
        this.pendingPath = '';
    }

    computeView() {
        let data = JSON.parse(JSON.stringify(this.rawBackendData));
        
        this.bundleList = data.map(grp => {
            // Standard Mode: Only show Standard Groups (Sort Order 1 or Name contains Standard)
            if (this.selectedPath === 'Standard' && !grp.isStandard) return null;

            // Accordion: Collapsed by default unless it's Standard group
            grp.isExpanded = (this.selectedPath === 'Standard' && grp.isStandard);
            grp.chevronIcon = grp.isExpanded ? 'utility:chevrondown' : 'utility:chevronright';
            grp.sectionClass = grp.isExpanded ? 'slds-section slds-is-open slds-m-bottom_small slds-card' : 'slds-section slds-m-bottom_small slds-card';

            grp.tasks = grp.tasks.map(t => {
                let isChecked = false;
                let isLocked = false;

                // Path Logic
                if (this.selectedPath === 'Standard') {
                    if (grp.isStandard) { isChecked = true; isLocked = true; }
                } else {
                    // Flexible: Standard tasks are auto-checked but unlocked
                    if (grp.isStandard) { isChecked = true; isLocked = false; }
                    // Retain previously selected flexible tasks
                    if (!grp.isStandard && t.isChecked) isChecked = true;
                }

                if (this.isReadOnly) isLocked = true;

                // Dynamic Label: Pre vs Post Drive
                let label = 'Days Prior';
                if (t.isPostDrive) label = 'Days After Drive';

                return {
                    ...t,
                    uniqueKey: grp.id + '-' + t.id,
                    isDriveDependent: t.schedulingMethod === 'Days Offset',
                    userOffset: (t.userOffset !== undefined && t.userOffset !== null) ? t.userOffset : t.defaultOffset,
                    userDate: t.userDate ? t.userDate : new Date().toISOString().slice(0, 10),
                    offsetLabel: label,
                    isChecked: isChecked,
                    isLocked: isLocked,
                    inputDisabled: !isChecked || isLocked || this.isReadOnly,
                    rowClass: isChecked ? 'slds-hint-parent slds-is-selected' : 'slds-hint-parent'
                };
            });

            const checkedCount = grp.tasks.filter(t => t.isChecked).length;
            grp.selectedCount = checkedCount;
            grp.isAllSelected = (checkedCount === grp.tasks.length && checkedCount > 0);

            return grp;
        }).filter(g => g !== null);
    }

    // --- EVENT HANDLERS ---
    handleToggleSection(event) {
        const bundleId = event.target.dataset.bundleId;
        this.updateData(grp => { if(grp.id === bundleId) grp.isExpanded = !grp.isExpanded; });
    }

    handleSelectAll(event) {
        const bundleId = event.target.dataset.bundleId;
        const checked = event.target.checked;
        this.updateData(grp => {
            if (grp.id === bundleId) {
                grp.tasks.forEach(t => {
                    if (!t.isLocked) { t.isChecked = checked; t.inputDisabled = !checked; }
                });
            }
        });
    }

    handleTaskCheck(event) {
        const bundleId = event.target.dataset.bundleId;
        const taskId = event.target.dataset.taskId;
        const checked = event.target.checked;
        this.updateData(grp => {
            if (grp.id === bundleId) {
                grp.tasks.forEach(t => { if(t.id === taskId) { t.isChecked = checked; t.inputDisabled = !checked; }});
            }
        });
    }

    handleOffsetChange(event) {
        const taskId = event.target.dataset.taskId;
        const bundleId = event.target.dataset.bundleId;
        this.updateData(grp => {
            if (grp.id === bundleId) grp.tasks.forEach(t => { if(t.id === taskId) t.userOffset = parseInt(event.target.value, 10); });
        });
    }

    handleDateChange(event) {
        const taskId = event.target.dataset.taskId;
        const bundleId = event.target.dataset.bundleId;
        this.updateData(grp => {
            if (grp.id === bundleId) grp.tasks.forEach(t => { if(t.id === taskId) t.userDate = event.target.value; });
        });
    }

    updateData(mutationFn) {
        this.bundleList = this.bundleList.map(grp => {
            mutationFn(grp);
            // Visual Updates
            if (grp.isExpanded) {
                grp.sectionClass = 'slds-section slds-is-open slds-m-bottom_small slds-card';
                grp.chevronIcon = 'utility:chevrondown';
            } else {
                grp.sectionClass = 'slds-section slds-m-bottom_small slds-card';
                grp.chevronIcon = 'utility:chevronright';
            }
            const count = grp.tasks.filter(t => t.isChecked).length;
            grp.selectedCount = count;
            grp.isAllSelected = (count === grp.tasks.length);
            return grp;
        });
    }

    handleSave() {
        this.isLoading = true;
        let taskSelections = [];
        let selectedPackageIds = new Set();

        this.bundleList.forEach(grp => {
            let hasSelection = false;
            grp.tasks.forEach(t => {
                if (t.isChecked) {
                    hasSelection = true;
                    // FLIP SIGN Logic for Post-Drive
                    let finalOffset = t.userOffset;
                    if(t.isPostDrive) finalOffset = -Math.abs(t.userOffset);
                    else finalOffset = Math.abs(t.userOffset);

                    taskSelections.push({
                        definitionId: t.id,
                        schedulingMethod: t.schedulingMethod,
                        userOffset: finalOffset,
                        userDate: t.userDate,
                        packageId: grp.id
                    });
                }
            });
            if (hasSelection && !grp.isStandard) selectedPackageIds.add(grp.id);
        });

        saveTaskPlans({ 
            recordId: this.recordId, 
            jsonPayload: JSON.stringify(taskSelections),
            selectedPackageIds: Array.from(selectedPackageIds),
            activePath: this.selectedPath
        })
        .then(() => {
            this.showToast('Success', 'Plan saved successfully!', 'success');
            this.isLoading = false;
            setTimeout(() => { eval("$A.get('e.force:refreshView').fire();"); }, 1000);
        })
        .catch(error => {
            console.error(error);
            this.showToast('Error', 'Failed to save plan.', 'error');
            this.isLoading = false;
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}