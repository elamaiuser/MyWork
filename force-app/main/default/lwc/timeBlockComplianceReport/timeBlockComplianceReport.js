import { LightningElement, track } from 'lwc';
import searchReport from '@salesforce/apex/TimeBlockComplianceReportController.searchReport';
import getTimeBlockPicklistByCO from '@salesforce/apex/TimeBlockComplianceReportController.getTimeBlockPicklistByCO';

export default class TimeBlockComplianceReport extends LightningElement {
    @track wrapper = {
        startDate: this.getTodayDate(),
        endDate: this.getTodayDate(),
        division: '',
        region: '',
        co: [],
        violationOnly: false,
        driveStatusFilter: ['Complete'],
        timeBlockIds: [],
        accountManagerName: ''
    };

    @track dataArry = [];
    @track columns = [];
    @track loaded = false;
    @track hasError = false;
    @track hasRecords = false;
    @track showPopup = false;
    @track errorMessageToDisplay = '';

    @track totalRecords = 0;
    @track totalCompliant = 0;
    @track compliancePercent = 0;

    
    @track sortBy = null;           
    @track sortDirection = 'asc';

    @track driveStatusOptions = [
        { label: 'Draft', value: 'Draft', selected: false },
        { label: 'System Generated', value: 'System Generated', selected: false },
        { label: 'Hold', value: 'Hold', selected: false },
        { label: 'Tentative', value: 'Tentative', selected: false },
        { label: 'Confirmed', value: 'Confirmed', selected: false },
        { label: 'Complete', value: 'Complete', selected: true },
        { label: 'Cancel', value: 'Cancel', selected: false }
    ];

    @track timeBlockOptions = [];

    getTodayDate() {
        const today = new Date();
        return today.toISOString().slice(0, 10);
    }

    get showNothing() {
        return false;
    }

    handleSelectedValues(event) {
        this.wrapper.startDate = event.detail.startDate;
        this.wrapper.endDate = event.detail.endDate;
        this.wrapper.division = event.detail.division || '';
        this.wrapper.region = event.detail.region || '';
        this.wrapper.co = event.detail.collectionop || [];

        if (this.wrapper.co && this.wrapper.co.length > 0) {
            this.fetchTimeBlockOptions(this.wrapper.co);
        } else {
            this.timeBlockOptions = [];
            this.wrapper.timeBlockIds = [];

            this.template.querySelectorAll('c-bsf-multi-select-combobox').forEach(element => {
                if (element.name === 'timeBlock') {
                    element.selectedItems = '-Select-';
                    element.options = [];
                    element.showOptions = false;
                    element.overritecurrent();
                }
            });
        }
}



    fetchTimeBlockOptions(coIds) {
        console.log('Calling getTimeBlockPicklistByCO with coIds:', coIds);
        getTimeBlockPicklistByCO({ coIds: coIds })
            .then(result => {
                console.log('Returned Time Block options:', JSON.stringify(result));
                this.timeBlockOptions = result;
            })
            .catch(error => {
                console.error('Error fetching TBs:', error);
            });
    }

    handleResetValues() {
        this.wrapper = {
            startDate: this.getTodayDate(),
            endDate: this.getTodayDate(),
            division: '',
            region: '',
            co: [],
            violationOnly: false,
            driveStatusFilter: ['Complete'],
            timeBlockIds: [],
            accountManagerName: ''
        };

        this.dataArry = [];
        this.columns = [];
        this.loaded = false;
        this.hasError = false;
        this.hasRecords = false;
        this.errorMessageToDisplay = '';

        this.totalRecords = 0;
        this.totalCompliant = 0;
        this.compliancePercent = 0;

        this.sortBy = null;
        this.sortDirection = 'asc';

        this.resetDriveStatusOptions();

        this.template.querySelectorAll('c-bsf-multi-select-combobox').forEach(element => {
            if (element.name === 'timeBlock') {
                element.selectedItems = '-Select-';
                element.overritecurrent();
            }
        });
    }

    resetDriveStatusOptions() {
        this.driveStatusOptions.forEach(opt => opt.selected = false);
        const combobox = this.template.querySelector('c-bsf-multi-select-combobox[name="driveStatus"]');
        if (combobox) {
            combobox.selectedItems = '-Select-';
            combobox.overritecurrent();
        }
    }

    handleDriveStatusChange(event) {
        const items = Array.isArray(event.detail) ? event.detail : JSON.parse(JSON.stringify(event.detail));
        this.wrapper.driveStatusFilter = items.map(i => i?.value);
    }

    handleDriveStatusClick() {
        const combobox = this.template.querySelector('c-bsf-multi-select-combobox[name="driveStatus"]');
        if (combobox) combobox.showOptions = true;
    }

    handleTimeBlockChange(event) {
        this.wrapper.timeBlockIds = event.detail.map(i => i?.value);
    }

    handleAccountManagerInput(event) {
        this.wrapper.accountManagerName = event.target.value;
    }

    handleViolationToggleChange(event) {
        this.wrapper.violationOnly = event.target.checked;
    }
    handleSort(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;

        this.performSearch();
    }

    handleSearch() {
        this.loaded = true;
        this.hasRecords = false;
        this.hasError = false;
        this.errorMessageToDisplay = '';
        this.dataArry = [];

        this.totalRecords = 0;
        this.totalCompliant = 0;
        this.compliancePercent = 0;

        this.performSearch();
    }

    performSearch() {
        this.loaded = true;

        const driveStatusClone = Array.isArray(this.wrapper.driveStatusFilter)
            ? [...this.wrapper.driveStatusFilter]
            : [];

        searchReport({
            startDateParam: this.wrapper.startDate,
            endDateParam: this.wrapper.endDate,
            coIds: this.wrapper.co,
            onlyViolations: this.wrapper.violationOnly,
            driveStatusList: driveStatusClone,
            timeBlockIds: this.wrapper.timeBlockIds,
            accountManagerName: this.wrapper.accountManagerName,
            sortField: this.sortBy,
            sortDirection: this.sortDirection
        })
            .then(result => {
                this.loaded = false;

                this.columns = result?.columnsInfo || [];
                this.dataArry = result?.dataWrapper || [];

                this.hasRecords = this.dataArry.length > 0;
                this.hasError = !this.hasRecords;
                this.errorMessageToDisplay = this.hasError ? 'No data found.' : '';

                if (this.hasRecords) {
                    this.totalRecords = this.dataArry.length;
                    this.totalCompliant = this.dataArry.filter(row => row.violation === 'true').length;

                    this.compliancePercent = this.totalRecords > 0
                        ? Math.round((this.totalCompliant / this.totalRecords) * 100)
                        : 0;
                }
            })
            .catch(error => {
                this.loaded = false;
                this.hasError = true;
                this.hasRecords = false;
                this.dataArry = [];
                this.columns = [];

                this.errorMessageToDisplay = error?.body?.message || 'Unknown error';
                console.error('searchReport error:', error);
            });
    }

    handleViewPdf() {
        this.showPopup = true;
    }

    handleClosePopupHandler() {
        this.showPopup = false;
    }

    exportToPdf() {
        window.open(this.getPopUpRedirectUrl, '_blank');
    }

    get getPopUpRedirectUrl() {
        const driveStatusParam = encodeURIComponent((this.wrapper.driveStatusFilter || []).join(','));
        const coParam = encodeURIComponent((this.wrapper.co || []).join(','));
        const tbParam = encodeURIComponent((this.wrapper.timeBlockIds || []).join(','));
        const accMgr = encodeURIComponent(this.wrapper.accountManagerName || '');

        return `/apex/TimeBlockCompliancePDF?startdate=${this.wrapper.startDate}` +
            `&enddate=${this.wrapper.endDate}` +
            `&region=${this.wrapper.region}` +
            `&co=${coParam}` +
            `&violationOnly=${this.wrapper.violationOnly}` +
            `&driveStatusFilter=${driveStatusParam}` +
            `&timeBlockFilter=${tbParam}` +
            `&accountManagerName=${accMgr}`;
    }

    exportToExcel() {
        const driveStatusParam = encodeURIComponent((this.wrapper.driveStatusFilter || []).join(','));
        const coParam = encodeURIComponent((this.wrapper.co || []).join(','));
        const tbParam = encodeURIComponent((this.wrapper.timeBlockIds || []).join(','));
        const accMgr = encodeURIComponent(this.wrapper.accountManagerName || '');

        window.open(
            `/apex/TimeBlockComplianceExcel?startdate=${this.wrapper.startDate}` +
            `&enddate=${this.wrapper.endDate}` +
            `&region=${this.wrapper.region}` +
            `&co=${coParam}` +
            `&violationOnly=${this.wrapper.violationOnly}` +
            `&driveStatusFilter=${driveStatusParam}` +
            `&timeBlockFilter=${tbParam}` +
            `&accountManagerName=${accMgr}`,
            '_blank'
        );
    }

    get disablePdfButton() {
        return !this.hasRecords;
    }
    get Hide() {
        return true;
    }
}