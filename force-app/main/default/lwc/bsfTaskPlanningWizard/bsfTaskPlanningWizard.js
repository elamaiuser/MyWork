import { LightningElement, track, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import getTaskBundles from '@salesforce/apex/BSF_TaskPlanningWizardController.getTaskBundles';
import saveTaskPlans from '@salesforce/apex/BSF_TaskPlanningWizardController.saveTaskPlans';

export default class BsfTaskPlanningWizard extends LightningElement {
    @api recordId;
    
    @track packageGroups = [];
    @track activePlanningPath;
    @track currentDriveStatus;
    @track objectApiName;
    @track isLoading = true;
    @track isPathChangeModalOpen = false;
    @track isPlanningLocked = false;
    @track isSaveConfirmationModalOpen = false;
    
    wiredResult;
    taskMetadataCache = [];
    pendingPlanningPath = '';
    isOverridden = false;

    get pathOptions() {
        return [
            { label: 'Standard Path', value: 'Standard' },
            { label: 'Flexible Path', value: 'Flexible' }
        ];
    }

    get isDataLoaded() { 
        return this.packageGroups.length > 0 && !this.isLoading; 
    }

    @wire(getTaskBundles, { recordId: '$recordId' })
    handleInitialDataLoad(result) {
        this.wiredResult = result;
        const { data, error } = result;        
        this.isLoading = true;
        if (data) {
            this.isLoading = false;
            this.objectApiName = data.objectApiName;
            this.activePlanningPath = data.currentPath || 'Standard';
            this.currentDriveStatus = data.driveStatus;
            const lockedStatuses = ['Confirmed', 'Complete'];
            this.isPlanningLocked = lockedStatuses.includes(data.driveStatus);
            this.isOverridden = data.isOverridden;
            this.taskMetadataCache = JSON.parse(JSON.stringify(data.packages));
            this.initializePackageDisplay();            
        } else if (error) {
            this.showToast('Error', 'Failed to load task packages.', 'error');
        }        
    }

    handlePathChangeRequest(event) {
        this.pendingPlanningPath = event.detail.value;
        this.isPathChangeModalOpen = true;
    }

    executePathChange() {
        this.activePlanningPath = this.pendingPlanningPath;
        this.isPathChangeModalOpen = false;
        this.initializePackageDisplay();
    }

    cancelPathChange() {
        this.isPathChangeModalOpen = false;
        this.pendingPlanningPath = '';
        const originalPath = this.activePlanningPath;
        this.activePlanningPath = null; // Force re-render to reset the UI state
        Promise.resolve().then(() => {
            this.activePlanningPath = originalPath;
        });
    }

    initializePackageDisplay() {
        // Deep clone the metadata to apply UI-specific logic
        const packages = JSON.parse(JSON.stringify(this.taskMetadataCache));

        // Determine if we are in a "Transition" state (Moving from Standard -> Flexible without saving yet)
        // In this state, we want to pre-select Standard tasks as a starting point.
        const isTransitioningFromStandard = (this.wiredResult && this.wiredResult.data && this.wiredResult.data.currentPath === 'Standard');

        this.packageGroups = packages.map(group => {
            // Standard Mode Filter: Only show standard groups
            if (this.activePlanningPath === 'Standard' && !group.isStandard) {
                return null;
            }

            // UI State Configuration
            group.isExpanded = (this.activePlanningPath === 'Standard' && group.isStandard);
            group.chevronIcon = group.isExpanded ? 'utility:chevrondown' : 'utility:chevronright';
            group.containerClass = group.isExpanded ? 'slds-section slds-is-open slds-m-bottom_small slds-card' : 'slds-section slds-m-bottom_small slds-card';
            group.showRequiredBadge = (group.isStandard && this.activePlanningPath === 'Standard');
            group.isReadOnlyHeader = group.isStandard || group.hideSelectAll;

            group.tasks = group.tasks.map(taskItem => {
                let isChecked = false;
                let isLocked = false;

                // Path-Based Default Logic
                if (this.activePlanningPath === 'Standard') {
                    if (group.isStandard) { isChecked = true; isLocked = true; }
                } else {
                    // In Flexible View:
                    if (isTransitioningFromStandard && group.isStandard) {
                        // Scenario: User just switched from Standard to Flexible (Unsaved).
                        // Default the standard tasks to Checked so they have a baseline to work from.
                        isChecked = true;
                    } else {
                        // Scenario: Existing Flexible Plan (Saved in DB).
                        // Trust the DB state. If user unchecked it previously, it stays unchecked.
                        isChecked = taskItem.isChecked;
                    }
                }

                if (this.isPlanningLocked) {
                    isLocked = true;
                }

                return {
                    ...taskItem,
                    uniqueKey: group.packageId + '-' + taskItem.taskDefinitionId,
                    isDriveDependent: taskItem.schedulingMethod === 'Days Offset',
                    userOffset: (taskItem.userOffset != null) ? taskItem.userOffset : taskItem.defaultOffset,
                    userDate: taskItem.userDate || new Date().toISOString().slice(0, 10),
                    offsetLabel: taskItem.isPostDrive ? 'Days After Drive' : 'Days Prior',
                    isChecked: isChecked,
                    isLocked: isLocked,
                    isInputDisabled: !isChecked || isLocked || this.isPlanningLocked,
                    rowClass: isChecked ? 'slds-hint-parent slds-is-selected' : 'slds-hint-parent'
                };
            });

            const checkedCount = group.tasks.filter(t => t.isChecked).length;
            group.selectedCount = checkedCount;
            group.isAllSelected = (checkedCount === group.tasks.length && checkedCount > 0);

            return group;
        }).filter(group => group !== null);
    }

    // --- INTERACTION HANDLERS ---

    handleToggleSection(event) {
        const packageId = event.target.dataset.packageId;
        this.updatePackageState(group => { 
            if(group.packageId === packageId) group.isExpanded = !group.isExpanded; 
        });
    }

    handleSelectAllInGroup(event) {
        const packageId = event.target.dataset.packageId;
        const checked = event.target.checked;
        this.updatePackageState(group => {
            if (group.packageId === packageId) {
                group.tasks.forEach(task => {
                    if (!task.isLocked) { 
                        task.isChecked = checked; 
                        task.isInputDisabled = !checked; 
                    }
                });
            }
        });
    }

    handleTaskSelection(event) {
        const taskId = event.target.dataset.taskId;
        const packageId = event.target.dataset.packageId;
        const checked = event.target.checked;
        this.updatePackageState(group => {
            if (group.packageId === packageId) {
                group.tasks.forEach(task => { 
                    if(task.taskDefinitionId === taskId) { 
                        task.isChecked = checked; 
                        task.isInputDisabled = !checked; 
                    }
                });
            }
        });
    }

    handleOffsetChange(event) {
        const taskId = event.target.dataset.taskId;
        const packageId = event.target.dataset.packageId;
        const value = parseInt(event.target.value, 10);
        this.updatePackageState(group => {
            if (group.packageId === packageId) {
                group.tasks.forEach(task => { if(task.taskDefinitionId === taskId) task.userOffset = value; });
            }
        });
    }

    handleDateChange(event) {
        const taskId = event.target.dataset.taskId;
        const packageId = event.target.dataset.packageId;
        const value = event.target.value;
        this.updatePackageState(group => {
            if (group.packageId === packageId) {
                group.tasks.forEach(task => { if(task.taskDefinitionId === taskId) task.userDate = value; });
            }
        });
    }

    updatePackageState(mutationFn) {
        this.packageGroups = this.packageGroups.map(group => {
            mutationFn(group);
            // Visual Refresh for the section
            group.containerClass = group.isExpanded ? 'slds-section slds-is-open slds-m-bottom_small slds-card' : 'slds-section slds-m-bottom_small slds-card';
            group.chevronIcon = group.isExpanded ? 'utility:chevrondown' : 'utility:chevronright';
            
            const count = group.tasks.filter(t => t.isChecked).length;
            group.selectedCount = count;
            group.isAllSelected = (count === group.tasks.length);
            return group;
        });
    }

    persistTaskPlan() {
        if (this.objectApiName !== 'Account' && this.activePlanningPath === 'Flexible' && !this.isOverridden) {
            this.isSaveConfirmationModalOpen = true;
            return;
        }
        this.executeSave();
    }

    executeSave() {
        this.isSaveConfirmationModalOpen = false;
        this.isLoading = true;
        const serializedTaskPayload = [];
        const selectedPackageIds = new Set();

        this.packageGroups.forEach(group => {
            let hasSelectionInGroup = false;
            group.tasks.forEach(task => {
                if (task.isChecked) {
                    hasSelectionInGroup = true;
                    
                    // Flip sign for Post-Drive persistence
                    const persistentOffset = task.isPostDrive ? -Math.abs(task.userOffset) : Math.abs(task.userOffset);
                    serializedTaskPayload.push({
                        definitionId: task.taskDefinitionId,
                        schedulingMethod: task.schedulingMethod,
                        userOffset: persistentOffset,
                        userDate: task.userDate,
                        packageId: group.packageId
                    });
                }
            });
            if (hasSelectionInGroup && !group.isStandard) {
                selectedPackageIds.add(group.packageId);
            }
        });

        saveTaskPlans({ 
            recordId: this.recordId, 
            jsonPayload: JSON.stringify(serializedTaskPayload),
            selectedPackageIds: Array.from(selectedPackageIds),
            activePath: this.activePlanningPath
        })
        .then(() => {
            this.showToast('Success', 'Plan has been applied successfully. Please allow a few minutes for the process to complete.', 'success');
            return refreshApex(this.wiredResult)
            .then(() => {
                notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
            });            
        })
        .catch(() => {
            this.showToast('Error', 'An error occurred while saving.', 'error');            
        })
        .finally(() => {
            this.isLoading = false;
        });
    }

    closeSaveModal() {
        this.isSaveConfirmationModalOpen = false;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}