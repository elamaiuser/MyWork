import { LightningElement, track } from 'lwc';
import searchReport from '@salesforce/apex/APComplianceReportController.searchReport';

export default class ApComplianceReport extends LightningElement {
    @track wrapper = {
        startDate: this.getTodayDate(),
        endDate: this.getTodayDate(),
        division: '',
        region: '',
        co: [],
        violationOnly: false,
        driveStatusFilter: [],
        includeTrades: true
    };

    @track dataArry = [];
    @track columns = [];
    @track loaded = false;
    @track hasError = false;
    @track hasRecords = false;
    @track showPopup = false;
    @track errorMessageToDisplay = '';
    @track totalRecords = 0;
    @track totalViolations = 0;
    @track violationPercent = 0;

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
    }

    handleResetValues() {
        this.wrapper = {
            startDate: this.getTodayDate(),
            endDate: this.getTodayDate(),
            division: '',
            region: '',
            co: [],
            violationOnly: false,
            driveStatusFilter: [],
            includeTrades: true
        };

        this.hasError = false;
        this.hasRecords = false;

        this.sortBy = null;
        this.sortDirection = 'asc';

        this.resetDriveStatusOptions();
    }

    resetDriveStatusOptions() {
        this.driveStatusOptions.forEach(opt => (opt.selected = false));
        const combobox = this.template.querySelector('c-bsf-multi-select-combobox[name="driveStatus"]');
        if (combobox) {
            combobox.selectedItems = '-Select-';
            combobox.overritecurrent();
        }
    }

    handleDriveStatusChange(event) {
        const items = Array.isArray(event.detail) ? event.detail : JSON.parse(JSON.stringify(event.detail));
        const driveStatusList = items.filter(i => i?.value).map(i => i.value);
        this.wrapper.driveStatusFilter = driveStatusList;
    }

    handleDriveStatusClick() {
        const combobox = this.template.querySelector('c-bsf-multi-select-combobox[name="driveStatus"]');
        if (combobox) combobox.showOptions = true;
    }

    handleViolationToggleChange(event) {
        this.wrapper.violationOnly = event.target.checked;
    }

    handleIncludeTradesChange(event) {
        this.wrapper.includeTrades = event.target.checked;
    }

    async handleSort(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;

        this.loaded = true;

        await new Promise(resolve => window.requestAnimationFrame(resolve));

        this.performSearch(true);
    }

    handleSearch() {
        this.loaded = true;
        this.hasRecords = false;
        this.hasError = false;

        this.dataArry = [];
        this.totalRecords = 0;
        this.totalViolations = 0;
        this.violationPercent = 0;
        this.sortBy = null;
        this.sortDirection = 'asc';

        this.performSearch(false);
    }

    performSearch(isSort) {
        this.loaded = true;

        const driveStatusClone = [...this.wrapper.driveStatusFilter];

        searchReport({
            startDt: this.wrapper.startDate,
            endDt: this.wrapper.endDate,
            division: this.wrapper.division,
            region: this.wrapper.region,
            coList: this.wrapper.co,
            driveStatusFilter: driveStatusClone,
            violationOnly: this.wrapper.violationOnly,
            includeTrades: this.wrapper.includeTrades,
            sortField: this.sortBy,
            sortDirection: this.sortDirection
        })
            .then(result => {
                // DO NOT keep Apex-returned proxies directly in datatable
                const safeData = (result?.dataWrapper || []).map(r => ({ ...r }));
                const safeCols = (result?.columnsInfo || []).map(c => ({ ...c }));

                // columns should not be re-set on every sort (reduces datatable resize/weakmap crashes)
                if (!this.columns || this.columns.length === 0 || !isSort) {
                    this.columns = safeCols;
                }

                this.dataArry = safeData;

                this.hasRecords = this.dataArry.length > 0;
                this.hasError = !this.hasRecords;
                this.errorMessageToDisplay = this.hasError ? 'No data found.' : '';

                if (this.hasRecords) {
                    this.totalRecords = this.dataArry.length;
                    this.totalViolations = this.dataArry.filter(r => r.violation === 'true').length;
                    this.violationPercent = Math.round((this.totalViolations / this.totalRecords) * 100);
                }

                this.loaded = false;
            })
            .catch(error => {
                this.loaded = false;
                this.hasError = true;
                this.errorMessageToDisplay = error?.body?.message || 'Unknown error';
                console.error(error);
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

    exportToExcel() {
        const driveStatusParam = encodeURIComponent((this.wrapper.driveStatusFilter || []).join(','));
        const coParam = encodeURIComponent((this.wrapper.co || []).join(','));
        window.open(
            `/apex/APComplianceExcel?startdate=${this.wrapper.startDate}&enddate=${this.wrapper.endDate}` +
            `&division=${encodeURIComponent(this.wrapper.division || '')}&region=${encodeURIComponent(this.wrapper.region || '')}` +
            `&co=${coParam}&violationOnly=${this.wrapper.violationOnly}` +
            `&driveStatusFilter=${driveStatusParam}&includeTrades=${this.wrapper.includeTrades}`,
            '_blank'
        );
    }

    get getPopUpRedirectUrl() {
        const driveStatusParam = encodeURIComponent((this.wrapper.driveStatusFilter || []).join(','));
        const coParam = encodeURIComponent((this.wrapper.co || []).join(','));
        return `/apex/BSFAPComplianceReportPDF?startdate=${this.wrapper.startDate}&enddate=${this.wrapper.endDate}` +
            `&division=${encodeURIComponent(this.wrapper.division || '')}&region=${encodeURIComponent(this.wrapper.region || '')}` +
            `&co=${coParam}&violationOnly=${this.wrapper.violationOnly}` +
            `&driveStatusFilter=${driveStatusParam}&includeTrades=${this.wrapper.includeTrades}`;
    }

    get disablePdfButton() {
        return !this.hasRecords;
    }

    get Hide() {
        return true;
    }
}