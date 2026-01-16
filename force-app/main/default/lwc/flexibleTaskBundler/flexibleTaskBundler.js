import { LightningElement, track, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getTaskBundles from '@salesforce/apex/FlexibleTaskBundleController.getTaskBundles';
import saveFlexiblePlan from '@salesforce/apex/FlexibleTaskBundleController.saveFlexiblePlan';

export default class FlexibleTaskBundler extends LightningElement {
    @api recordId; // Account or Opportunity ID
    @track bundleList = [];
    @track selectedPath = 'Standard';
    @track isLoading = true;
    @track showConfirmation = false;
    
    // Internal State
    rawBackendData = [];
    pendingPath = ''; // Stores path selection while modal is open

    get pathOptions() {
        return [
            { label: 'Standard Path', value: 'Standard' },
            { label: 'Flexible Path', value: 'Flexible' }
        ];
    }

    get pathDescription() {
        return this.selectedPath === 'Standard' 
            ? 'Deploys the default 12-week task process.' 
            : 'Allows custom selection of task bundles and timelines.';
    }

    get showBundles() {
        return this.bundleList.length > 0 && !this.isLoading;
    }

    // --- 1. DATA LOAD ---
    @wire(getTaskBundles, { recordId: '$recordId' })
    wiredData({ error, data }) {
        this.isLoading = true;
        if (data) {
            // 1. Set Path from DB (or Default to Standard)
            // If data.currentPath is null/undefined, use 'Standard'
            this.selectedPath = data.currentPath ? data.currentPath : 'Standard';
            // Store Bundle Data
            this.rawBackendData = JSON.parse(JSON.stringify(data.bundles));
            // Detect if previously saved as Flexible, otherwise default Standard
            // (Assuming backend sends a signal or checking if any Flex bundles are pre-selected)
            // For now, defaulting UI to Standard unless logic dictates otherwise
            this.computeView();
        } else if (error) {
            console.error(error);
            this.showToast('Error', 'Failed to load task configuration.', 'error');
        }
        this.isLoading = false;
    }

    // --- 2. MODAL & PATH SWITCHING ---
    handlePathChangeRequest(event) {
        this.pendingPath = event.detail.value;
        // Always confirm before switching logic
        this.showConfirmation = true;
    }

    confirmPathChange() {
        this.selectedPath = this.pendingPath;
        this.showConfirmation = false;
        this.computeView();
    }

    cancelPathChange() {
        this.showConfirmation = false;
        // Revert radio button visually requires resetting variable logic 
        // effectively relying on the fact that selectedPath hasn't changed yet
        this.pendingPath = '';
    }

    // --- 3. CORE LOGIC (VIEW COMPUTATION) ---
    computeView() {
        let data = JSON.parse(JSON.stringify(this.rawBackendData));
        
        this.bundleList = data.map(grp => {
            // Filter: In Standard mode, only Standard bundle is visible
            if (this.selectedPath === 'Standard' && !grp.isStandard) return null;

            // Accordion State: Default Collapsed unless it's the Standard Group in Standard Mode
            grp.isExpanded = (this.selectedPath === 'Standard' && grp.isStandard); 
            grp.chevronIcon = grp.isExpanded ? 'utility:chevrondown' : 'utility:chevronright';
            grp.sectionClass = grp.isExpanded 
                ? 'slds-section slds-is-open slds-m-bottom_small slds-card slds-card_boundary' 
                : 'slds-section slds-m-bottom_small slds-card slds-card_boundary';

            // Process Tasks
            grp.tasks = grp.tasks.map(t => {
                let isChecked = false;
                let isLocked = false;

                // LOGIC: Standard Path
                if (this.selectedPath === 'Standard') {
                    if (grp.isStandard) { 
                        isChecked = true; 
                        isLocked = true; // Mandatory
                    }
                } 
                // LOGIC: Flexible Path
                else {
                    if (grp.isStandard) { 
                        isChecked = true; // Default to checked
                        isLocked = false; // EDITABLE (AC Requirement)
                    }
                    // For Flexible bundles, retain state if previously checked
                    if (!grp.isStandard && t.isChecked) {
                        isChecked = true;
                    }
                }
                
                return {
                    ...t,
                    uniqueKey: grp.id + '-' + t.id,
                    isDriveDependent: t.timingType === 'Drive Dependent',
                    // Use saved offset/date if exists, else default
                    userOffset: (t.userOffset !== undefined && t.userOffset !== null) ? t.userOffset : t.defaultOffset,
                    userDate: t.userDate ? t.userDate : new Date().toISOString().slice(0, 10),
                    isChecked: isChecked,
                    isLocked: isLocked,
                    inputDisabled: !isChecked || isLocked,
                    rowClass: isChecked ? 'slds-hint-parent slds-is-selected' : 'slds-hint-parent'
                };
            });

            // Calculate Header Counts
            const checkedCount = grp.tasks.filter(t => t.isChecked).length;
            grp.selectedCount = checkedCount;
            grp.isAllSelected = (checkedCount === grp.tasks.length && checkedCount > 0);

            return grp;
        }).filter(g => g !== null);
    }

    // --- 4. EVENT HANDLERS ---

    handleToggleSection(event) {
        const bundleId = event.target.dataset.bundleId;
        this.updateData(grp => {
            if (grp.id === bundleId) {
                grp.isExpanded = !grp.isExpanded;
            }
        });
    }

    handleSelectAll(event) {
        const bundleId = event.target.dataset.bundleId;
        const checked = event.target.checked;
        this.updateData(grp => {
            if (grp.id === bundleId) {
                grp.tasks.forEach(t => {
                    if (!t.isLocked) {
                        t.isChecked = checked;
                        t.inputDisabled = !checked;
                        t.rowClass = checked ? 'slds-hint-parent slds-is-selected' : 'slds-hint-parent';
                    }
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
                grp.tasks.forEach(t => {
                    if (t.id === taskId) {
                        t.isChecked = checked;
                        t.inputDisabled = !checked;
                        t.rowClass = checked ? 'slds-hint-parent slds-is-selected' : 'slds-hint-parent';
                    }
                });
            }
        });
    }

    handleOffsetChange(event) {
        const taskId = event.target.dataset.taskId;
        const bundleId = event.target.dataset.bundleId;
        this.updateData(grp => {
            if (grp.id === bundleId) {
                grp.tasks.forEach(t => { if(t.id === taskId) t.userOffset = parseInt(event.target.value, 10); });
            }
        });
    }

    handleDateChange(event) {
        const taskId = event.target.dataset.taskId;
        const bundleId = event.target.dataset.bundleId;
        this.updateData(grp => {
            if (grp.id === bundleId) {
                grp.tasks.forEach(t => { if(t.id === taskId) t.userDate = event.target.value; });
            }
        });
    }

    // Helper to mutate state efficiently
    updateData(mutationFn) {
        this.bundleList = this.bundleList.map(grp => {
            mutationFn(grp);
            
            // Re-calc Visuals
            if (grp.isExpanded) {
                grp.sectionClass = 'slds-section slds-is-open slds-m-bottom_small slds-card slds-card_boundary';
                grp.chevronIcon = 'utility:chevrondown';
            } else {
                grp.sectionClass = 'slds-section slds-m-bottom_small slds-card slds-card_boundary';
                grp.chevronIcon = 'utility:chevronright';
            }
            
            // Re-calc Counts
            const checkedCount = grp.tasks.filter(t => t.isChecked).length;
            grp.selectedCount = checkedCount;
            grp.isAllSelected = (checkedCount === grp.tasks.length);
            return grp;
        });
    }

    // --- 5. SAVE LOGIC ---
    handleSave() {
        this.isLoading = true;
        let taskSelections = [];
        let selectedBundleIds = new Set();

        this.bundleList.forEach(grp => {
            let bundleHasSelection = false;

            grp.tasks.forEach(t => {
                if (t.isChecked) {
                    bundleHasSelection = true;
                    taskSelections.push({
                        masterId: t.id,
                        timingType: t.timingType,
                        userOffset: t.userOffset,
                        userDate: t.userDate
                    });
                }
            });

            // Capture Selected Bundles for Reporting
            if (bundleHasSelection && grp.id !== 'STANDARD_GRP' && grp.id !== 'MISC_GRP') {
                selectedBundleIds.add(grp.id);
            }
        });

        const payload = JSON.stringify(taskSelections);
        const bundleList = Array.from(selectedBundleIds);

        saveFlexiblePlan({ 
            recordId: this.recordId, 
            jsonPayload: payload,
            selectedBundleIds: bundleList,
            activePath: this.selectedPath
        })
        .then(() => {
            this.showToast('Success', 'Drive Plan saved successfully!', 'success');
            this.isLoading = false;
            // Force refresh to update standard fields
            setTimeout(() => {
                 // eslint-disable-next-line no-eval
                eval("$A.get('e.force:refreshView').fire();");
            }, 1000);
        })
        .catch(error => {
            console.error(error);
            this.showToast('Error', 'Failed to save plan. ' + (error.body ? error.body.message : ''), 'error');
            this.isLoading = false;
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}