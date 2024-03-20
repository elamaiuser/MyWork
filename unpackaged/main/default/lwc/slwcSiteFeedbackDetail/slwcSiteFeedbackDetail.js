import { LightningElement, track, api } from "lwc";
import { getValueFromEvent } from "c/slwcUtils";
import { keyBy, uniqueId, isString, debounce } from "c/lodash";
import { SITE_FEEDBACK_ACCESS_MODE } from 'c/slwcConstants';
import TIME_ZONE from '@salesforce/i18n/timeZone';
import * as slwcDateUtils from 'c/slwcDateUtils';
import { DateTime } from 'c/luxon';
import { driveService, driveQueryModel, locationQueryModel, locationService } from 'c/dataService';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class SlwcSiteFeedbackDetail extends LightningElement {
    @track DRIVE_TABLE_COLUMNS = [
        {label: 'Drive Name', fieldName: 'recordPageUrl', type: 'url', hideDefaultActions: false, wrapText: true, typeAttributes: {label: { fieldName: 'name' }, target: '_blank' }, hideDefaultActions: true },
        {label: 'UFID', fieldName: 'ufid', type: 'text', hideDefaultActions: false, wrapText: true, hideDefaultActions: true },
        {label: 'Drive Type', fieldName: 'typeOfDrive', type: 'text', hideDefaultActions: true, wrapText: true },
        {label: 'Drive Status', fieldName: 'status', type: 'text', hideDefaultActions: false, wrapText: true, hideDefaultActions: true },
        {label: 'Drive Date', fieldName: 'driveDate', type: 'date-local', typeAttributes: { year: 'numeric', month: 'short', day: '2-digit' }, hideDefaultActions: true, wrapText: true },
        {label: 'Start Time', fieldName: 'startTime', type: 'time', hideDefaultActions: true, wrapText: true },
        {label: 'End Time', fieldName: 'endTime', type: 'time', hideDefaultActions: true, wrapText: true },
        {label: '# of Staff Requested', fieldName: 'totalStaffRequested', type: 'number', cellAttributes: { alignment: 'left' }, hideDefaultActions: true },
        {label: '# of Machines Requested', fieldName: 'totalEquipmentRequested', type: 'number', cellAttributes: { alignment: 'left' }, hideDefaultActions: true },
        {label: 'Proj Reg Donors', fieldName: 'projectedRegisteredDonors', type: 'number', cellAttributes: { alignment: 'left' }, hideDefaultActions: true },
    ];

    @track SITE_TABLE_COLUMNS = [
        {label: 'Site Name', fieldName: 'recordPageUrl', type: 'url', hideDefaultActions: false, wrapText: true, typeAttributes: {label: { fieldName: 'name' }, target: '_blank' }, hideDefaultActions: true },
        {label: 'Building Name', fieldName: 'siteBuildingName', type: 'text', hideDefaultActions: false, wrapText: true, hideDefaultActions: true },
        {label: 'Room Name', fieldName: 'roomName', type: 'text', hideDefaultActions: true, wrapText: true },
        {label: 'City', fieldName: 'city', type: 'text', hideDefaultActions: false, wrapText: true, hideDefaultActions: true },
        {label: 'State', fieldName: 'state', type: 'text', hideDefaultActions: false, wrapText: true, hideDefaultActions: true },
    ];

    @track _isOpen = false;
    @api
    get isOpen() {
        return this._isOpen;
    }
    set isOpen(value) {
        this._isOpen = value;
        if(this._isOpen) {
            this.init();
        }
    }
    @api record;
    @api job;
    @api site;
    @api accessMode = SITE_FEEDBACK_ACCESS_MODE.RESOURCE; 

    @track model = {};
    @track showSpinner = false;
    @track searchDriveModalData = {};
    @track searchSiteModalData = {};
    @track errorMessages = [];

    get dateUtils() {
        return slwcDateUtils.getInstance({
          timezone: TIME_ZONE
        });
    }

    get isCreate() {
        return !this.record;
    }

    get isReadonly() {
        return this.record && this.record.status !== 'Not Submitted';
    }

    get enableEffectiveDates() {
        if(this.accessMode === SITE_FEEDBACK_ACCESS_MODE.RESOURCE) return false;
        return true;
    }

    get disableSiteLookup() {
        if(this.accessMode === SITE_FEEDBACK_ACCESS_MODE.RESOURCE) return true;
        return this.isReadonly;
    }
    
    get showDriveLookup() {
        if(this.accessMode === SITE_FEEDBACK_ACCESS_MODE.RESOURCE) return false;
        return this.model.site;
    }

    get amountOptions() {
        const step = 5;
        const start = 5;
        const end = 75;
        let options = [];
        for(let i = start; i <= end; i = i + step) {
            options.push({
                label: i,
                value: i
            });
        }

        return options;
    }

    connectedCallback() {
    }

    exceptionHandler = (error) => {
        this.dispatchEvent(new ShowToastEvent({
          message: error.message,
          variant: 'error',
          mode: 'dismissable',
        }));
    }

    showLoading() {
        this.showSpinner = true;
    }

    hideLoading() {
        this.showSpinner = false;
    }

    init() {
        this.accessMode = this.accessMode || SITE_FEEDBACK_ACCESS_MODE.RESOURCE;

        if(this.accessMode === SITE_FEEDBACK_ACCESS_MODE.RESOURCE && (!this.job || !this.site)) return;

        if (this.isCreate) {
            if(this.accessMode === SITE_FEEDBACK_ACCESS_MODE.RESOURCE) {
                this.model = {
                    jobId: this.job.id,
                    site: this.site,
                    siteId: this.site.id,
                    status: 'Not Submitted',
                    routeApprovalRequestTo: 'Route to CO Team Supervisor'
                }
            } else {
                this.model = {
                    status: 'Not Submitted',
                    routeApprovalRequestTo: 'Route to DRD Manager'
                }
            }
        } else {
            this.model = {
              ...this.record
            }

            if(this.model.resourceRoleGroup && isString(this.model.resourceRoleGroup)) {
                this.model.resourceRoleGroup = this.model.resourceRoleGroup.split(';');
            }
        }
    }

    handleSiteChanged(event) {
        this.model.site = event.detail.selection;
        this.model.siteId = event.detail.selection ? event.detail.selection.id : null;

        this.model.drive = null;
        this.model.driveId = null;
    }

    handleDriveChanged(event) {
        this.model.drive = event.detail.selection;
        this.model.driveId = event.detail.selection ? event.detail.selection.id : null;
    }

    handleOnChange(event) {
        const eventName = event.target.name;
        const value = getValueFromEvent(event);
        this.model[eventName] = value;
    }

    handleSave() {
        if (this.validate()) {
            let eventModal = new CustomEvent("save", {
                detail: {
                    ...this.model,
                    key: this.model.key || uniqueId("detail_")
                }
            });
            this.dispatchEvent(eventModal);
        }
    }

    handleSubmit() {
        if (this.validate()) {
            let eventModal = new CustomEvent("save", {
                detail: {
                    ...this.model,
                    status: 'Submitted',
                    key: this.model.key || uniqueId("detail_")
                }
            });
            this.dispatchEvent(eventModal);
        }
    }

    validate() {
        this.errorMessages = [];

        let allInputsCorrect = [
            ...this.template.querySelectorAll("lightning-input"),
            ...this.template.querySelectorAll("c-slwc-picklist"),
            ...this.template.querySelectorAll("c-slwc-multi-picklist"),
            ...this.template.querySelectorAll("lightning-combobox"),
            ...this.template.querySelectorAll("c-slwc-lookup"),
            ...this.template.querySelectorAll("c-slwc-select"),
        ];

        if (this.enableEffectiveDates) {
            if (this.model.effectiveStartDate && this.model.effectiveEndDate) {
                if (this.model.effectiveStartDate >= this.model.effectiveEndDate) {
                    this.errorMessages.push({
                        message: 'Effective Start Date must before Effective End Date.'
                    })
                }
            }
        }

        return !this.errorMessages.length && allInputsCorrect.reduce((validSoFar, inputField) => {
            inputField.reportValidity();
            return validSoFar && inputField.checkValidity();
        }, true);
    }

    closeModal() {
        const eventModal = new CustomEvent("close");
        this.dispatchEvent(eventModal);
    }

    /* Search Drive Modal */
    fetchDrives() {
        const transformDrive = (item) => {
            return {
              ...item,
              recordPageUrl: '/' + item.id,
            }
        }

        this.searchDriveModalData.showSpinner = true;
        let queryModel = new driveQueryModel();
        let service = new driveService();
        const filters = this.searchDriveModalData.filters;

        queryModel.startDate = filters.startDate;
        queryModel.endDate = filters.endDate;
        queryModel.statuses = filters.statuses;
        queryModel.eventTypes = filters.driveTypes;
        queryModel.locationIds = [this.model.site.id];
        queryModel.ufid = filters.ufid;

        return service.query(queryModel)
        .then((result) => {
          this.searchDriveModalData.drives = (result || []).map(transformDrive);
        })
        .catch((e) => this.exceptionHandler(e))
        .finally(() => {
            this.searchDriveModalData.showSpinner = false;
        });
    }

    initSearchDriveModalFilters() {
        let filters = {};
        filters.ufid = '';
        filters.startDate = this.dateUtils.startOfWeek(DateTime.local(), 0).toISODate();
        filters.endDate = DateTime.fromISO(filters.startDate).plus({
            day: 6
        }).toISODate();
        filters.driveStatuses = ['System Generated', 'Hold', 'Tentative', 'Confirmed', 'Complete'];
        filters.driveTypes = ['Fixed Site', 'Mobile'];
            
        return filters;
    }

    handleSearchDriveTableRowSelection(event) {
        this.searchDriveModalData.selectedDrive = (event.detail.selectedRows && event.detail.selectedRows.length) ? event.detail.selectedRows[0] : null;
    }
    
    handleSearchDriveModalFiltersChanged(event) {
        if(event.currentTarget.name === 'ufid') {
            this.debounceFunc && this.debounceFunc.cancel();
            this.debounceFunc = debounce(() => {
                let value = getValueFromEvent(event);
                this.searchDriveModalData.filters.ufid = value;

                this.fetchDrives();
            }, 700);
            this.debounceFunc();
            return;
        }

        if (event.type === 'weekdatechange') {
            this.searchDriveModalData.filters = {
                ...this.searchDriveModalData.filters, 
                startDate: event.detail.startDate,
                endDate: event.detail.endDate
            }
        } else {
            let value = getValueFromEvent(event);
            this.searchDriveModalData.filters[event.currentTarget.name] = value;
        }

        this.fetchDrives();
    }

    showSearchDriveModal() {
        this.searchDriveModalData = {
            isOpen: true,
            showSpinner: false,
            selectedDrive: null,
            drives: [],
            filters: this.initSearchDriveModalFilters()
        }

        this.fetchDrives();
    }

    closeSearchDriveModal() {
        this.searchDriveModalData = {};
    }

    saveSearchDriveModal() {
        if(!this.searchDriveModalData.selectedDrive) {
            this.dispatchEvent(new ShowToastEvent({
                message: 'Please select 1 Drive.',
                variant: 'error',
                mode: 'dismissable',
            }));
            return;
        }

        this.handleDriveChanged({
            detail: {
                selection: this.searchDriveModalData.selectedDrive
            }
        })

        this.closeSearchDriveModal();
    }

    /* Search Site Modal */
    fetchSites() {
        const transformSite = (item) => {
            return {
              ...item,
              recordPageUrl: '/' + item.id,
            }
        }

        this.searchSiteModalData.showSpinner = true;
        let queryModel = new locationQueryModel();
        let service = new locationService();
        const filters = this.searchSiteModalData.filters;
        queryModel.name = filters.name;
        
        return service.query(queryModel)
        .then((result) => {
          this.searchSiteModalData.sites = (result || []).map(transformSite);
        })
        .catch((e) => this.exceptionHandler(e))
        .finally(() => {
            this.searchSiteModalData.showSpinner = false;
        });
    }

    initSearchSiteModalFilters() {
        let filters = {};
        filters.name = '';
            
        return filters;
    }

    handleSearchSiteTableRowSelection(event) {
        this.searchSiteModalData.selectedSite = (event.detail.selectedRows && event.detail.selectedRows.length) ? event.detail.selectedRows[0] : null;
    }
    
    handleSearchSiteModalFiltersChanged(event) {
        if(event.currentTarget.name === 'name') {
            this.debounceFunc && this.debounceFunc.cancel();
            this.debounceFunc = debounce(() => {
                let value = getValueFromEvent(event);
                this.searchSiteModalData.filters.name = value;

                this.fetchSites();
            }, 700);
            this.debounceFunc();
            return;
        }

        let value = getValueFromEvent(event);
        this.searchSiteModalData.filters[event.currentTarget.name] = value;

        this.fetchSites();
    }

    showSearchSiteModal() {
        this.searchSiteModalData = {
            isOpen: true,
            showSpinner: false,
            selectedSite: null,
            sites: [],
            filters: this.initSearchSiteModalFilters()
        }

        this.fetchSites();
    }

    closeSearchSiteModal() {
        this.searchSiteModalData = {};
    }

    saveSearchSiteModal() {
        if(!this.searchSiteModalData.selectedSite) {
            this.dispatchEvent(new ShowToastEvent({
                message: 'Please select 1 Site.',
                variant: 'error',
                mode: 'dismissable',
            }));
            return;
        }

        this.handleSiteChanged({
            detail: {
                selection: this.searchSiteModalData.selectedSite
            }
        })

        this.closeSearchSiteModal();
    }
}