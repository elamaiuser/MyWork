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
    @track violationPercentage = 0;

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
        this.resetDriveStatusOptions();
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
        let driveStatusList = [];
        const items = Array.isArray(event.detail) ? event.detail : JSON.parse(JSON.stringify(event.detail));
        for (let i in items) {
            if (items[i] && items[i].value) {
                driveStatusList.push(items[i].value);
                this.driveStatusOptions
                    .filter(item => item.value === items[i].value)
                    .forEach(item => item.selected = true);
            }
        }
        this.wrapper.driveStatusFilter = driveStatusList;
        console.log("Final driveStatusFilter:", this.wrapper.driveStatusFilter);
    }

    handleDriveStatusClick() {
        const combobox = this.template.querySelector('c-bsf-multi-select-combobox[name="driveStatus"]');
        if (combobox) {
            combobox.showOptions = true;
        }
    }

    handleViolationToggleChange(event) {
        this.wrapper.violationOnly = event.target.checked;
    }

    handleIncludeTradesChange(event) {
        this.wrapper.includeTrades = event.target.checked;
    }

    handleSearch() {
    this.loaded = true;
    this.hasRecords = false;
    this.hasError = false;
    this.dataArry = [];
    this.totalRecords = 0;
    this.totalViolations = 0;
    this.violationPercent = 0;

    const driveStatusClone = [...this.wrapper.driveStatusFilter];

    searchReport({
        startDt: this.wrapper.startDate,
        endDt: this.wrapper.endDate,
        division: this.wrapper.division,
        region: this.wrapper.region,
        coList: this.wrapper.co,
        violationOnly: this.wrapper.violationOnly,
        driveStatusFilter: driveStatusClone, // ✅ clone sent
        includeTrades: this.wrapper.includeTrades
    })
    .then(result => {
        this.loaded = false;
        this.columns = result.columnsInfo;
        this.dataArry = result.dataWrapper;
        this.hasRecords = this.dataArry.length > 0;
        this.hasError = !this.hasRecords;
        this.errorMessageToDisplay = this.hasError ? 'No data found.' : '';

        if (this.hasRecords) {
            this.totalRecords = this.dataArry.length;
            this.totalViolations = this.dataArry.filter(row => row.violation === 'true').length;
            this.violationPercent = Math.round((this.totalViolations / this.totalRecords) * 100);
        }
    })
    .catch(error => {
        this.loaded = false;
        this.hasError = true;
        this.errorMessageToDisplay = error.body?.message || 'Unknown error';
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
        const driveStatusParam = this.wrapper.driveStatusFilter.join(',');
        window.open(`/apex/APComplianceExcel?startdate=${this.wrapper.startDate}&enddate=${this.wrapper.endDate}&division=${this.wrapper.division}&region=${this.wrapper.region}&co=${this.wrapper.co}&violationOnly=${this.wrapper.violationOnly}&driveStatusFilter=${driveStatusParam}&includeTrades=${this.wrapper.includeTrades}`, '_blank');

    }

    get getPopUpRedirectUrl() {
       const driveStatusParam = this.wrapper.driveStatusFilter.join(',');
        return `/apex/BSFAPComplianceReportPDF?startdate=${this.wrapper.startDate}&enddate=${this.wrapper.endDate}&division=${this.wrapper.division}&region=${this.wrapper.region}&co=${this.wrapper.co}&violationOnly=${this.wrapper.violationOnly}&driveStatusFilter=${driveStatusParam}&includeTrades=${this.wrapper.includeTrades}`;

    }

    convertToCSV(data) {
        if (!data || !data.length) return '';
        const header = Object.keys(data[0]).join(',');
        const rows = data.map(row => Object.values(row).map(v => `"${v}"`).join(','));
        return [header, ...rows].join('\n');
    }

    get disablePdfButton() {
        return !this.hasRecords;
    }
    get Hide() {
    return true;  
}
}