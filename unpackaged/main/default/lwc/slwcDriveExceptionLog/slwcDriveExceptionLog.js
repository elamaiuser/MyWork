import { LightningElement, track, api, wire } from 'lwc';
import { exceptionService, exceptionQueryModel } from 'c/dataService';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const COLUMNS = [
    { label: 'Name', fieldName: 'recordUrl', type: 'url', hideDefaultActions: false, wrapText: true, typeAttributes:{label: { fieldName: 'name' }, target: '_blank'}},
    { label: 'Job', fieldName: 'jobUrl', type: 'url', hideDefaultActions: false, wrapText: true, typeAttributes:{label: { fieldName: 'jobName' }, target: '_blank'}},
    { label: 'Resource', fieldName: 'resourceName', type: 'text', hideDefaultActions: true, wrapText: true },
    { label: 'Exception', fieldName: 'exception', type: 'text', hideDefaultActions: true, wrapText: true, cellAttributes: {wrapText: true} },
    { label: 'Priority', fieldName: 'priority', type: 'text', hideDefaultActions: true, wrapText: true },
    { label: 'Status', fieldName: 'status', type: 'text', hideDefaultActions: true, wrapText: true }
];

export default class SlwcDriveExceptionLog extends LightningElement {
    @api recordId;
    @api isReadonly;

    @track showSpinner = false;
    @track columns = COLUMNS;
    @track exceptionLog = [];
    @track selectedExceptionLog = [];

    get hasException() {
        return this.exceptionLog && this.exceptionLog.length;
    }

    get btnCloseExceptionLabel() {
        return `Close Exception (${this.selectedExceptionLog.length} selected)`;
    }

    get btnCloseExceptionDisabled() {
        return this.selectedExceptionLog.length === 0;
    }


    connectedCallback() {
        if (this.recordId) {
            this.initialize(this.recordId);
        }
    }

    showLoading = () => {
        this.showSpinner = true;
    }

    hideLoading = () => {
        this.showSpinner = false;
    }

    initialize(recordId) {
        console.log("initialize");
        if(!recordId) return;

        this.showLoading();
        this.fetchExceptionData()
        .catch(error => console.log(error))
        .finally(this.hideLoading);
    }

    fetchExceptionData() {
        let service = new exceptionService();
        let query = new exceptionQueryModel();
        query.driveIds = [this.recordId];
        query.statuses = ['Open'];
        return Promise.resolve()
            .then(() => {
                return service.query(query)
            })
            .then((result) => {
                this.selectedExceptionLog = [];
                this.exceptionLog = (result || []).map(exception => {
                    exception.recordUrl = '/' + exception.id;
                    if (exception.job) {
                        exception.jobUrl = exception.jobId ? '/' + exception.jobId : '';
                        exception.jobName = exception.job.resourceRole ? exception.job.resourceRole : exception.job.assetType;
                    }
                    return exception;
                })
            })
    }

    handleRowSelection(event) {
        this.selectedExceptionLog = (event.detail.selectedRows || []);
    }

    handleCloseException() {
        let exceptionLog = [];
        this.selectedExceptionLog.forEach((item) => {
            exceptionLog.push({
                id: item.id,
                status: 'Closed'
            });
        });
        this.showSpinner = true;
        let service = new exceptionService();
        service.saveList(exceptionLog)
            .then((result) => {
                this.dispatchEvent(new ShowToastEvent({
                    message: 'Exception log was closed successfully.',
                    variant: 'success',
                    mode: 'dismissable'
                }));
                return this.fetchExceptionData();
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }
}