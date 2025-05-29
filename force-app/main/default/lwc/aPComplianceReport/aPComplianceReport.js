import { LightningElement, track } from 'lwc';
import searchReport from '@salesforce/apex/APComplianceReportController.searchReport';

export default class ApComplianceReport extends LightningElement {
    @track wrapper = {
        startDate: this.getTodayDate(),
        endDate: this.getTodayDate(),
        division: '',
        region: '',
        co: [] 
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

    getTodayDate() {
        let today = new Date();
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
            co: []
        };
        this.hasError = false;
        this.hasRecords = false;
    }

   /* handleSearch() {
    this.loaded = true;
    this.hasRecords = false;
    this.hasError = false;
    this.dataArry = [];
    this.violationPercent = 0;

    searchReport({
        startDt: this.wrapper.startDate,
        endDt: this.wrapper.endDate,
        division: this.wrapper.division,
        region: this.wrapper.region,
        co: this.wrapper.co
    })
    .then(result => {
        this.loaded = false;
        this.columns = result.columnsInfo;
        this.dataArry = result.dataWrapper;
        this.hasRecords = this.dataArry.length > 0;
        this.hasError = !this.hasRecords;
        this.errorMessageToDisplay = this.hasError ? 'No data found.' : '';

        if (this.hasRecords) {
            const total = this.dataArry.length;
            const violated = this.dataArry.filter(row => row.violation === 'true').length;
            this.violationPercent = Math.round((violated / total) * 100);
        }
    })
    .catch(error => {
        this.loaded = false;
        this.hasError = true;
        this.errorMessageToDisplay = error.body?.message || 'Unknown error';
        console.error(error);
    });
}*/

 handleSearch() {
    this.loaded = true;
    this.hasRecords = false;
    this.hasError = false;
    this.dataArry = [];
    this.totalRecords = 0;
    this.totalViolations = 0;
    this.violationPercent = 0;

    searchReport({
        startDt: this.wrapper.startDate,
        endDt: this.wrapper.endDate,
        division: this.wrapper.division,
        region: this.wrapper.region,
        coList: this.wrapper.co
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
    window.open(`/apex/APComplianceExcel?startdate=${this.wrapper.startDate}&enddate=${this.wrapper.endDate}&division=${this.wrapper.division}&region=${this.wrapper.region}&co=${this.wrapper.co}`, '_blank');
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

    get getPopUpRedirectUrl() {
        return `/apex/BSFAPComplianceReportPDF?startdate=${this.wrapper.startDate}&enddate=${this.wrapper.endDate}&division=${this.wrapper.division}&region=${this.wrapper.region}&co=${this.wrapper.co}`;
    }
}