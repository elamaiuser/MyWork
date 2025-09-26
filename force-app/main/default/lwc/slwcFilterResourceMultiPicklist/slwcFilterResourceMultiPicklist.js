import {
    LightningElement,
    track,
    api
} from 'lwc';
import {
    classNames
} from 'c/slwcUtils';
import {
    cloneDeep,
    debounce
} from 'c/lodash';
import * as slwcUtils from 'c/slwcUtils';

const MODE = {
    ALL_JOBS: 'ALL_JOBS',
    PINNED_JOB: 'PINNED_JOB'
}

const VARIANT = {
    DEFAULT: 'DEFAULT',
    DISTANCE_SORTABLE: 'DISTANCE_SORTABLE',
    LINKED_DRIVE: 'LINKED_DRIVE'
}

export default class SlwcFilterResourceMultiPicklist extends LightningElement {
    @api container;
    @api singleSelect = false;
    @api variant = VARIANT.DEFAULT;
    @api mode = MODE.ALL_JOBS;
    @track _defaultValues = {
        callOut: false,
        onCall: false,
        prevCancelled: false,
        assignedToLinkedDrives: false,
        weeklyHours: false,
        selectedResourcesTag: [],
        selectedResourceRoles: [],
        selectedResourceEmploymentTypes: [],
        weeklyHoursRange: {
            start: 0,
            end: 40
        },
        queryText: '',
        cancelledDriveQueryText: ''
    };
    @api
    get defaultValues() {
        return this._defaultValues;
    }
    set defaultValues(value) {
        this._defaultValues = value || this._defaultValues;
    }
    
    @track _defaultSortValues = {
        sortBy: 'name',
        sortDirection: 'asc'
    };
    @api
    get defaultSortValues() {
        return this._defaultSortValues;
    }
    set defaultSortValues(value) {
        this._defaultSortValues = value || this._defaultSortValues;
    }

    @track filterPopverState = {
        ...this._defaultValues
    }
    @track clonedFilterPopverState = cloneDeep(this.filterPopverState);

    @track sortPopverState = {
        ...this._defaulSorttValues
    }
    @track clonedSortPopverState = cloneDeep(this.sortPopverState);

    @api resourceTagsOption = []

    @track showFilterPopover = false;
    @track filterPopoverPosition = null;

    @track showSortPopover = false;
    @track sortPopoverPosition = null;

    connectedCallback() {
        this.initDefaultValues();
    }

    get picklistElement() {
        return this.template.querySelector('.slds-button-group');
    }

    get picklistElementPosition() {
        if (!this.picklistElement) return null;
        return this.picklistElement.getBoundingClientRect();
    }

    get customClass() {
        return {
            filterPopover: classNames('slds-popover slds-popover_panel slds-nubbin_top-left filter-filters__popover', {
                'slds-fade-in-open': this.showFilterPopover
            }),
            sortPopover: classNames('slds-popover slds-popover_panel slds-nubbin_top-left filter-filters__popover', {
                'slds-fade-in-open': this.showSortPopover
            }),
            filterPopoverBackdrop: classNames('slds-backdrop', {
                'slds-backdrop--open': this.showFilterPopover || this.showSortPopover
            })
        }
    }

    get customStyle() {
        return {
            filterPopover: this.filterPopoverPosition ? [
                `top: ${this.filterPopoverPosition.top}px`,
                `left: ${this.filterPopoverPosition.left}px`
            ].join(';') : '',
            sortPopover: this.sortPopoverPosition ? [
                `top: ${this.sortPopoverPosition.top}px`,
                `left: ${this.sortPopoverPosition.left}px`
            ].join(';') : '',
        }
    }

    get isFiltered() {
        return true;
        // return this.filterPopverState.selectedResourcesTag.length > 0 ||
        //     this.filterPopverState.selectedResourceRoles.length > 0 ||
        //     this.filterPopverState.selectedResourceEmploymentTypes.length > 0 ||
        //     this.filterPopverState.callOut ||
        //     this.filterPopverState.onCall ||
        //     this.filterPopverState.prevCancelled ||
        //     this.filterPopverState.assignedToLinkedDrives
    }

    get isSorted() {
        return this.sortPopverState.sortBy && this.sortPopverState.sortDirection;
    }

    get filterButtonVartiant() {
        return this.isFiltered ? 'brand' :''
    }

    get sortButtonVartiant() {
        return '';
        // return this.isSorted ? 'brand' :''
    }

    get showCallOutFilter() {
        return this.mode === MODE.PINNED_JOB;
    }

    get sortByOptions() {
        const sortByDistanceData = this.variant === VARIANT.DISTANCE_SORTABLE
            ? [
                { label: 'Driving Roles - Travel Distance To', value: 'drivingRolesTravelDistanceTo' },
                { label: 'Driving Roles - Travel Distance Back', value: 'drivingRolesTravelDistanceBack' },
                { label: 'Staff Roles - Travel Distance To', value: 'staffRolesTravelDistanceTo' },
                { label: 'Staff Roles - Travel Distance Back', value: 'staffRolesTravelDistanceBack' },
            ]
            : [];

        if(this.mode === MODE.PINNED_JOB) {
            return [{
                label: 'Name',
                value: 'name'
            }, {
                label: 'Seniority Rank',
                value: 'seniorityRank'
            }, {
                label: 'Weekly Hours',
                value: 'weeklyHours'
            }, ...sortByDistanceData]
        } else {
            return [{
                label: 'Name',
                value: 'name'
            }, {
                label: 'Seniority Rank',
                value: 'seniorityRank'
            }, {
                label: 'Weekly Hours',
                value: 'weeklyHours'
            }, ...sortByDistanceData]
        }
    }

    get sortDirectionOptions() {
        return [{
            label: "ASC",
            value: 'asc'
        }, {
            label: 'DESC',
            value: 'desc'
        }]
    }

    get showAssignedLinkedDrivesFilter() {
        return this.variant !== VARIANT.LINKED_DRIVE;
    }

    get showWeeklyHoursMinMaxRangeText() {
        return this.clonedFilterPopverState.weeklyHours ? '0-100' : '';
    }
    
    initDefaultValues = () => {
        this.filterPopverState.selectedResourcesTag = cloneDeep(this.resourceTagsOption.filter(item => {
            return !!this.defaultValues.selectedResourcesTag.find(selected => selected.value === item.value);
        }))

        this.filterPopverState.selectedResourceRoles = cloneDeep(this.defaultValues.selectedResourceRoles);
        this.filterPopverState.selectedResourceEmploymentTypes = cloneDeep(this.defaultValues.selectedResourceEmploymentTypes);
        this.filterPopverState.weeklyHoursRange = cloneDeep(this.defaultValues.weeklyHoursRange);

        this.filterPopverState.callOut = !!this.defaultValues.callOut;
        this.filterPopverState.onCall = !!this.defaultValues.onCall;
        this.filterPopverState.prevCancelled = !!this.defaultValues.prevCancelled;
        this.filterPopverState.assignedToLinkedDrives = !!this.defaultValues.assignedToLinkedDrives;
        this.filterPopverState.weeklyHours = !!this.defaultValues.weeklyHours;
    }

    initDefaultSortValues = () => {
        this.sortPopverState.sortBy = this.defaultSortValues.sortBy;
        this.sortPopverState.sortDirection = this.defaultSortValues.sortDirection;
    }

    setFilterPopoverPosition = () => {
        if (!this.picklistElement) return;

        const picklistPosition = this.picklistElementPosition;
        this.filterPopoverPosition = {
            top: picklistPosition.y + picklistPosition.height,
            left: 0
        }
    }

    setSortPopoverPosition = () => {
        if (!this.picklistElement) return;

        const picklistPosition = this.picklistElementPosition;
        this.sortPopoverPosition = {
            top: picklistPosition.y + picklistPosition.height,
            left: 0
        }
    }

    openFilterPopover = () => {
        this.showFilterPopover = true;
        this.initDefaultValues();
        this.setFilterPopoverPosition();

        this.clonedFilterPopverState = cloneDeep(this.filterPopverState);
    }

    closeFilterPopover = () => {
        this.showFilterPopover = false;
    }

    openSortPopover = () => {
        this.showSortPopover = true;
        this.initDefaultSortValues();
        this.setSortPopoverPosition();

        this.clonedSortPopverState = cloneDeep(this.sortPopverState);
    }
    
    closeSortPopover = () => {
        this.showSortPopover = false;
    }

    applyFilter = () => {
        this.sendData()
        this.closeFilterPopover();
    }

    applySort = () => {
        this.sendSortData()
        this.closeSortPopover();
    }

    handleResourceTagChanged = (event) => {
        this.clonedFilterPopverState.selectedResourcesTag = cloneDeep(event.detail.selectedValues);
    }

    handleResourceRolesChanged = (event) => {
        this.clonedFilterPopverState.selectedResourceRoles = cloneDeep(event.detail.selectedValues);
    }

    handleResourceEmploymentTypesChanged = (event) => {
        this.clonedFilterPopverState.selectedResourceEmploymentTypes = cloneDeep(event.detail.selectedValues);
    }

    handleWeeklyHoursRangeChanged = (event) => {
        this.clonedFilterPopverState.weeklyHoursRange = cloneDeep(event.detail);
    }

    handleSearchText(event) {
        const value = slwcUtils.getValueFromEvent(event);
        this.clonedFilterPopverState.queryText = value;
        this.sendData()
    }
    handleSearchTextDebounce = debounce(this.handleSearchText, 500);

    handleSearchText_CancelledDrive(event) {
        const value = slwcUtils.getValueFromEvent(event);
        this.clonedFilterPopverState.cancelledDriveQueryText = value;
        this.sendData()
    }
    handleSearchText_CancelledDriveDebounce = debounce(this.handleSearchText_CancelledDrive, 500);

    handleChange(event) {
        event.stopPropagation();
        
        const value = slwcUtils.getValueFromEvent(event);
        this.clonedFilterPopverState[event.currentTarget.name] = value;
    }

    handleSortChange(event) {
        event.stopPropagation();
        
        const value = slwcUtils.getValueFromEvent(event);
        this.clonedSortPopverState[event.currentTarget.name] = value;
    }

    sendData() {
        this.filterPopverState = cloneDeep(this.clonedFilterPopverState);
        const valuesChangeEvent = new CustomEvent('change', {
            detail: {
                value: this.filterPopverState,
            }
        });
        this.dispatchEvent(valuesChangeEvent);
    }

    sendSortData() {
        this.sortPopverState = cloneDeep(this.clonedSortPopverState);
        const valuesChangeEvent = new CustomEvent('sortchange', {
            detail: {
                value: this.sortPopverState,
            }
        });
        this.dispatchEvent(valuesChangeEvent);
    }
}