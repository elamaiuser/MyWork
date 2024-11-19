import { LightningElement, api, track } from 'lwc';
import { orderBy } from 'c/lodash';

export default class SlwcAdvancedDatatable extends LightningElement {
    @api fetchDataFunc;
    @api fetchParams;
    @api columnDefinitions;


    @track showSpinnerCount;
    @track data = {};
    @track sortOption = {};

    get showSpinner() {
        return this.showSpinnerCount > 0;
    }
    
    exceptionHandler = (error) => {
        new debugLogService().captureDebugLog(error);
        this.dispatchEvent(new ShowToastEvent({
            message: error.message,
            variant: 'error',
            mode: 'dismissable',
        }));
    }

    showLoading = () => {
        this.showSpinnerCount++;
    }

    hideLoading = () => {
        this.showSpinnerCount--;
        if(this.showSpinnerCount < 0) {
            this.showSpinnerCount = 0;
        } 
    }

    connectedCallback() {
        this.initSort();
        this.init();
    }

    init = () => {
        if (this.fetchDataFunc) {
            this.showLoading();
            this.fetchDataFunc(this.fetchParams)
            .then((data) => {
                this.data = data;
            })
            .catch(error => this.exceptionHandler(error))
            .finally(this.hideLoading);
        }
    }

    initSort() {
        this.sortOption = {
            fieldName: 'createdDate',
            sortDirection : 'desc'
        };
    }

    sortData() {
        if(!this.sortOption) return;
        const fieldName = this.sortOption.fieldName;
        const sortDirection = this.sortOption.sortDirection;
        this.data = orderBy(this.data, [fieldName], [sortDirection]);
    }

    handleSortChanged(event) {
        const fieldName = event.detail.fieldName;
        const sortDirection = event.detail.sortDirection;
    
        this.sortOption = {
          fieldName: fieldName,
          sortDirection: sortDirection
        }
    
        this.sortData();
    }
}