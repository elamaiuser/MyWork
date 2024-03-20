import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { sObjectType, driveChangeRequestQueryModel, driveChangeRequestService, opportunityService } from 'c/dataService';

export default class SlwcMassOpportunityListenDriveChange extends LightningElement {
    @api opportunityIds = [];
    
    @track COLUMNS = [
        { label: 'Name', sortable: false, fieldName: 'recordUrl', type: 'url', hideDefaultActions: true, wrapText: true, typeAttributes: { label: { fieldName: 'name' }, target: '_blank' } },
        { label: 'Drive Name', initialWidth: 300, sortable: false, fieldName: 'driveRecordUrl', type: 'url', hideDefaultActions: false, wrapText: true, typeAttributes: { label: { fieldName: 'driveName' }, target: '_blank' } },
        { label: 'Drive Date', sortable: false, fieldName: 'driveDate', type: 'date-local', typeAttributes: { year: 'numeric', month: 'short', day: '2-digit' }, hideDefaultActions: true },
        { label: 'Drive Type', sortable: false, fieldName: 'driveType', type: 'text', hideDefaultActions: true, wrapText: true },
        { label: 'Start Time', sortable: false, fieldName: 'driveStartTime', type: 'time', hideDefaultActions: true, wrapText: true },
        { label: 'End Time', sortable: false, fieldName: 'driveEndTime', type: 'time', hideDefaultActions: true, wrapText: true },
        { label: 'Approval Status', sortable: false, fieldName: 'status', type: 'text', hideDefaultActions: true, wrapText: true },
        {
            label: '', type: 'actionButton', fieldName: 'id', hideDefaultActions: true, initialWidth: 100, typeAttributes: {
                rowActions: [
                    {
                        name: 'runSingle',
                        label: 'Run',
                        variant: 'brand',
                        clickAction: (event) => {
                            const record = this.driveChangeRequests.find(item => item.id === event.currentTarget.dataset['value']);
                            if(!record) return;
                            this.handleRunSingleButton(record);
                        }
                    }
                ]
            }
        },
    ];

    @track RUN_ALL_RESULT_TABLE_COLUMNS = [
        { label: 'Name', sortable: false, fieldName: 'recordUrl', type: 'url', hideDefaultActions: true, wrapText: true, typeAttributes: { label: { fieldName: 'name' }, target: '_blank' } },
        { label: 'Drive Name', initialWidth: 200, sortable: false, fieldName: 'driveRecordUrl', type: 'url', hideDefaultActions: false, wrapText: true, typeAttributes: { label: { fieldName: 'driveName' }, target: '_blank' } },
        { label: 'Drive Date', sortable: false, fieldName: 'driveDate', type: 'date-local', typeAttributes: { year: 'numeric', month: 'short', day: '2-digit' }, hideDefaultActions: true },
        { label: 'Drive Type', sortable: false, fieldName: 'driveType', type: 'text', hideDefaultActions: true, wrapText: true },
        { label: 'Result', initialWidth: 200, sortable: false, fieldName: 'resultMessage', type: 'text', hideDefaultActions: false, wrapText: true },
    ];

    @track showSpinner = false;
    @track driveChangeRequests = [];
    @track generateDriveModalData = {};
    @track runAllModalData = {};

    connectedCallback() {
        this.init();
    }
    
    exceptionHandler = (error) => {
        this.dispatchEvent(new ShowToastEvent({
            message: error.message,
            variant: 'error',
            mode: 'dismissable',
        }));
    }

    showLoading = () => {
        this.showSpinner = true;
    }

    hideLoading = () => {
        this.showSpinner = false;
    }

    init = () => {
        this.fetchDriveChangeRequests()
    }

    fetchDriveChangeRequests = () => {
        const transformItem = (item) => {
            return {
                ...item,
                recordUrl: '/' + item.id,
                driveRecordUrl: '/' + item.driveId 
            }
        };

        if(!this.opportunityIds.length) { 
            return Promise.resolve()
                .then(() => {
                    this.driveChangeRequests = [];
                })
        }
        
        this.showLoading();
        let service = new driveChangeRequestService();
        let queryModel = new driveChangeRequestQueryModel();
        queryModel.opportunityIds = this.opportunityIds;
        queryModel.statuses = ['Pending'];

        return service.query(queryModel)
        .then((result = []) => {
            this.driveChangeRequests = result.map(transformItem);
        })
        .catch(error => this.exceptionHandler(error))
        .finally(this.hideLoading);
    }

    handleRefreshButton = () => {
        this.fetchDriveChangeRequests();
    }

    handleRunAllButton = () => {
        this.showRunAllModal(this.driveChangeRequests);
    }

    handleRunSingleButton = (record) => {
        this.showGenerateDriveModal(record.id);
    }

    /* generate drive modal */
    showGenerateDriveModal = (recordId) => {
        this.generateDriveModalData = {
            isOpen: true,
            recordId: recordId
        }
    }

    closeGenerateDriveModal = (event) => {
        const { needToRefreshPage } = event.detail;
        this.generateDriveModalData = {};

        if(needToRefreshPage) {
            this.handleRefreshButton();
        }
    }

    /* run all modal */
    showRunAllModal = (diveChangeRequests = []) => {
        if(!diveChangeRequests.length) {
            this.dispatchEvent(new ShowToastEvent({
                message: 'There are no pending drive change requests.',
                variant: 'error',
                mode: 'dismissable',
            }));
            return;
        }

        this.runAllModalData = {
            finishedAll: false,
            records: diveChangeRequests,
            processedRecords: [],
            isOpen: true
        }

        this.runNextRecord();
    }

    closeRunAllModal = () => {
        this.runAllModalData = {};
        this.handleRefreshButton();
    }

    runNextRecord = () => {
        if(!this.runAllModalData || !this.runAllModalData.isOpen) return;
        
        let { records , currentRecordId } = this.runAllModalData;
        let currentRecordIndex = records.findIndex(item => item.id === currentRecordId);
        currentRecordIndex = currentRecordIndex < 0 ? 0 : currentRecordIndex + 1;
        if(currentRecordIndex > records.length - 1) {
            //no more record to run
            this.runAllModalData.currentRecordId = null;
            this.runAllModalData.currentRecord = null;
            this.runAllModalData.finishedAll = true;
            return;
        }
        
        this.runAllModalData.currentRecordId = null;
        setTimeout(() => {
            this.runAllModalData.currentRecordId = records[currentRecordIndex].id;
            this.runAllModalData.currentRecord = records[currentRecordIndex];
        });
    }
   
    afterFinishGenerateDriveModalHook = (event) => {
        const { recordId, result, resultMessage } = event.detail; //recordId was modified in generateDriveModal component so cannot use it here
        const { currentRecordId, records } = this.runAllModalData;
        let record = records.find(item => item.id === currentRecordId);
        this.runAllModalData.processedRecords.push({
            ...record,
            resultMessage: resultMessage
        });

        Promise.resolve()
        .then(() => {
            if(result) {                
                this.showLoading();
                let service = new opportunityService();
                return service.save({
                    id: record.opportunityId,
                    processingStatus: 'Mass Update Processed'
                })
                .catch(error => this.exceptionHandler(error))
                .finally(this.hideLoading);
            }
        })
        .then(() => {
            this.runNextRecord();
        })
    }
}