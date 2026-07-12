/**
 * @File Name          : genericRelatedListLWC.js
 * @Description        : LWC replacement for the GenericRelatedList Aura component.
 *                       Accepts structured object/field inputs instead of a raw SOQL string,
 *                       delegating safe query construction to GenericRelatedListLWCController.
 *                       Replicates all Aura functionality:
 *                         - Related list card with icon, count, and View All
 *                         - Edit / View / Delete row actions
 *                         - Hyperlink columns, date format types, ORDER BY
 *                         - File upload modal (for Files header)
 *                         - Full-screen View All with sortable columns and page-based pagination
 * @Author             :
 * Ver       Date            Author              Modification
 * 1.0       2024                                Initial Version
 */
import { LightningElement, api, track } from 'lwc';
import { NavigationMixin }              from 'lightning/navigation';
import { ShowToastEvent }               from 'lightning/platformShowToastEvent';
import getRecords                       from '@salesforce/apex/GenericRelatedListLWCController.getRecords';
import deleteRecords                    from '@salesforce/apex/GenericRelatedListLWCController.deleteRecords';
import getContentDocumentId             from '@salesforce/apex/ARCFileUploadController.getContentDocumentId';
import FORM_FACTOR                      from '@salesforce/client/formFactor';
import CURRENT_USER_ID                  from '@salesforce/user/Id';
import { RefreshEvent }                 from 'lightning/refresh';


const DATE_COLUMN_LABELS = [' Drive Date', 'Logged Date', 'Due Date', 'Close Date'];

export default class GenericRelatedList extends NavigationMixin(LightningElement) {

    @api headerName;
    @api iconName;
    @api objectApiName;
    @api childObjectName;
    @api fieldsApiNames;
    @api filterFieldApiName;
    @api columnName;
    @api recordButton = 'Edit,Delete';
    @api hyperLinkColumn;
    @api fieldwithOrderBy;
    @api dateFormatType;
    @api additionalFilter;
    @api recordId;
    @api currentRecordId;
    @api useLoggedInUserId    = false;
    @api useContentDocumentId = false;

    @track _resolvedIds    = null;
    @track tableData       = [];
    @track columns         = [];
    @track isLoading       = false;
    @track showFileModal   = false;
    @track numberOfRecords = 0;
    @track _hasMore        = false;
    @track _objectName     = '';
    @track _recordName     = '';

    @track showViewAll          = false;
    @track viewAllData          = [];
    @track viewAllColumns       = [];
    @track viewAllLoading       = false;
    @track viewAllHasMore       = false;
    @track viewAllPage          = 1;
    @track viewAllSortedBy      = '';
    @track viewAllSortedDir     = 'asc';
    @track viewAllSortedByLabel = '';

    recordToDisplay = 5;
    recordOffset    = 0;

    

    connectedCallback() {
    window.addEventListener('popstate', this.handlePopState);

    if (this.useContentDocumentId) {
        getContentDocumentId({ recordid: this.effectiveCurrentRecordId })
            .then(ids => {
                this._resolvedIds = ids || [];
                this._loadRecords();
            })
            .catch(() => {
                this._resolvedIds = [];
                this._loadRecords();
            });
    } else {
        this._resolvedIds = Array.isArray(this.recordId) ? this.recordId : [this.recordId];
        this._loadRecords();
    }
}
disconnectedCallback() {
    window.removeEventListener('popstate', this.handlePopState);
}

handlePopState = () => {
    if (this.showViewAll) {
        this.showViewAll = false;
    }
}
    _loadRecords() {
        if (!this._resolvedIds || !this.childObjectName || !this.filterFieldApiName) {
            return;
        }
        this.isLoading = true;
        const ids = this._resolvedIds;

        getRecords({
            recordId          : ids,
            columnLabels      : this.columnName,
            objectApiName     : this.childObjectName,
            fieldsApiNames    : this.fieldsApiNames,
            filterFieldApiName: this.filterFieldApiName,
            recordLimit       : this.recordToDisplay,
            recordOffset      : this.recordOffset,
            fieldwithOrderBy  : this.fieldwithOrderBy,
            additionalFilter  : this.additionalFilter
        })
        .then(result => {
            this.isLoading       = false;
            this.numberOfRecords = result.counts || 0;
            this._hasMore        = result.hasMore || false;
            this._objectName     = result.objectName || '';
            if (result.recordName) {
                this._recordName = result.recordName.Name || '';
            }
            this.tableData = (result.sObjectList || []).map(record => ({
                ...record,
                linkName: '/' + record.Id
            }));
            this._buildColumns(result.columnNames);
        })
        .catch(() => {
            this.isLoading = false;
        });
    }

    _buildColumns(fieldApiNamesFromServer) {
        const labelArray    = this.columnName       ? this.columnName.split(',')        : [];
        const fieldArray    = fieldApiNamesFromServer ? fieldApiNamesFromServer.split(',') : [];
        const hyperlinkCols = this.hyperLinkColumn   ? this.hyperLinkColumn.split(',')   : [];
        const columnArray   = [];

        for (let i = 0; i < labelArray.length; i++) {
            const label     = labelArray[i];
            const fieldName = fieldArray[i] ? fieldArray[i].trim() : '';
            const col       = { label, hideDefaultActions: true };

            if (hyperlinkCols.includes(label)) {
                col.type           = 'url';
                col.fieldName      = 'linkName';
                col.typeAttributes = { label: { fieldName }, target: '_self' };
            } else if (DATE_COLUMN_LABELS.includes(label)) {
                col.fieldName = fieldName;
                if (this.dateFormatType === 'Custom Date Format') {
                    col.type           = 'date-local';
                    col.typeAttributes = { month: 'numeric', day: 'numeric', year: 'numeric' };
                } else if (this.dateFormatType === 'SF OOTB Date Format') {
                    col.type           = 'date';
                    col.typeAttributes = {
                        day: 'numeric', month: 'short', year: 'numeric',
                        hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: true
                    };
                } else {
                    col.type = 'date-local';
                }
            } else {
                col.fieldName = fieldName;
            }
            columnArray.push(col);
        }

        const actions = [];
        if (this.recordButton) {
            this.recordButton.split(',').forEach(btn => {
                const trimmed = btn.trim();
                if (trimmed) actions.push({ label: trimmed, name: trimmed.toLowerCase() });
            });
        }
        if (actions.length) {
            columnArray.push({ type: 'action', typeAttributes: { rowActions: actions } });
        }
        this.columns = columnArray;
    }

    

    handleRowAction(event) {
        const { action, row } = event.detail;
        switch (action.name) {
            case 'edit':
                this[NavigationMixin.Navigate]({
                    type      : 'standard__recordPage',
                    attributes: { recordId: row.Id, actionName: 'edit' }
                });
                break;
            case 'view':
                this[NavigationMixin.Navigate]({
                    type      : 'standard__recordPage',
                    attributes: { recordId: row.Id, actionName: 'view' }
                });
                break;
            case 'delete':
                this._deleteRecord(row.Id);
                break;
            default:
                break;
        }
    }

    _deleteRecord(recId) {
        deleteRecords({ lstRecordId: recId })
            .then(() => {
                this._loadRecords();
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({
                    title  : 'Error deleting record',
                    message: (error.body && error.body.message) ? error.body.message : String(error),
                    variant: 'error'
                }));
            });
    }

    handleViewAll() {
    this.showViewAll        = true;
    this.viewAllData        = [];
    this.viewAllColumns     = [];
    this.viewAllPage        = 1;
    this.viewAllHasMore     = false;

    window.history.pushState({ viewAllOpen: true }, '');

    if (this.fieldwithOrderBy) {
        const parts = this.fieldwithOrderBy.trim().split(/\s+/);
        this.viewAllSortedBy      = parts[0] || '';
        this.viewAllSortedDir     = (parts[1] || 'desc').toLowerCase();
        this.viewAllSortedByLabel = parts[0] || '';
    }
    this._loadViewAllPage();
}

    handleCloseViewAll() {
    this.showViewAll = false;

    if (window.history.state && window.history.state.viewAllOpen) {
        window.history.back();
    }
}

    handleViewAllNext() {
        this.viewAllPage++;
        this._loadViewAllPage();
    }

    handleViewAllPrev() {
        this.viewAllPage--;
        this._loadViewAllPage();
    }

    handleRefreshViewAll() {
        this.viewAllPage    = 1;
        this.viewAllData    = [];
        this.viewAllHasMore = false;
        this._loadViewAllPage();
    }

    get effectiveCurrentRecordId() {
    return this.currentRecordId || this.recordId;
}

    _loadViewAllPage() {
        if (!this._resolvedIds || !this.childObjectName || !this.filterFieldApiName) return;
        this.viewAllLoading = true;
        const ids    = this._resolvedIds;
        const offset = (this.viewAllPage - 1) * this._viewAllPageSize;
        const sortBy = this.viewAllSortedBy
            ? (this.viewAllSortedBy + ' ' + this.viewAllSortedDir)
            : this.fieldwithOrderBy;

        getRecords({
            recordId          : ids,
            columnLabels      : this.columnName,
            objectApiName     : this.childObjectName,
            fieldsApiNames    : this.fieldsApiNames,
            filterFieldApiName: this.filterFieldApiName,
            recordLimit       : this._viewAllPageSize,
            recordOffset      : offset,
            fieldwithOrderBy  : sortBy,
            additionalFilter  : this.additionalFilter
        })
        .then(result => {
            this.viewAllLoading = false;
            this.viewAllHasMore = result.hasMore || false;
            this.viewAllData    = (result.sObjectList || []).map(record => ({
                ...record,
                linkName: '/' + record.Id
            }));
            if (this.viewAllColumns.length === 0) {
                this._buildViewAllColumns(result.columnNames);
            }
        })
        .catch(() => {
            this.viewAllLoading = false;
        });
    }

    _buildViewAllColumns(fieldApiNamesFromServer) {
        const labelArray    = this.columnName       ? this.columnName.split(',')        : [];
        const fieldArray    = fieldApiNamesFromServer ? fieldApiNamesFromServer.split(',') : [];
        const hyperlinkCols = this.hyperLinkColumn   ? this.hyperLinkColumn.split(',')   : [];
        const columnArray   = [];

        for (let i = 0; i < labelArray.length; i++) {
            const label     = labelArray[i];
            const fieldName = fieldArray[i] ? fieldArray[i].trim() : '';
            const col       = { label, hideDefaultActions: true, sortable: true };

            if (hyperlinkCols.includes(label)) {
                col.type           = 'url';
                col.fieldName      = 'linkName';
                col.typeAttributes = { label: { fieldName }, target: '_self' };
            } else if (DATE_COLUMN_LABELS.includes(label)) {
                col.fieldName = fieldName;
                if (this.dateFormatType === 'Custom Date Format') {
                    col.type           = 'date-local';
                    col.typeAttributes = { month: 'numeric', day: 'numeric', year: 'numeric' };
                } else if (this.dateFormatType === 'SF OOTB Date Format') {
                    col.type           = 'date';
                    col.typeAttributes = {
                        day: 'numeric', month: 'short', year: 'numeric',
                        hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: true
                    };
                } else {
                    col.type = 'date-local';
                }
            } else {
                col.fieldName = fieldName;
            }
            columnArray.push(col);
        }

        const actions = [];
        if (this.recordButton) {
            this.recordButton.split(',').forEach(btn => {
                const trimmed = btn.trim();
                if (trimmed) actions.push({ label: trimmed, name: trimmed.toLowerCase() });
            });
        }
        if (actions.length) {
            columnArray.push({ type: 'action', typeAttributes: { rowActions: actions } });
        }
        this.viewAllColumns = columnArray;
    }

    handleViewAllSort(event) {
        const { fieldName, sortDirection } = event.detail;
        this.viewAllSortedBy      = fieldName;
        this.viewAllSortedDir     = sortDirection;
        this.viewAllPage          = 1;
        const col = this.viewAllColumns.find(c => c.fieldName === fieldName);
        this.viewAllSortedByLabel = col ? col.label : fieldName;
        this._loadViewAllPage();
    }

    handleShowModal() {
        this.showFileModal = true;
    }

handleHideModal() {
        this.showFileModal = false;

        this.dispatchEvent(new RefreshEvent());

        this.dispatchEvent(new CustomEvent('refreshcustomcomponent'));

        if (this.effectiveCurrentRecordId && this.isFilesHeader) {
            getContentDocumentId({ recordid: this.effectiveCurrentRecordId })
                .then(ids => {
                    this._resolvedIds = ids || [];
                    this.recordOffset = 0;
                    this._loadRecords();
                })
                .catch(() => {
                    this._resolvedIds = [];
                    this.recordOffset = 0;
                    this._loadRecords();
                });
        } else {
            this.recordOffset = 0;
            this._loadRecords();
        }
    }

    get hasData() {
        return this.tableData && this.tableData.length > 0;
    }

    get countDisplay() {
        return this._hasMore ? (this.recordToDisplay + '+') : this.numberOfRecords;
    }

    get viewAllPrevDisabled() {
        return this.viewAllPage <= 1 || this.viewAllLoading;
    }

    get viewAllNextDisabled() {
        return !this.viewAllHasMore || this.viewAllLoading;
    }

    get _viewAllPageSize() {
        return FORM_FACTOR === 'Small' ? 10 : 20;
    }

    get showRowNumbers() {
        return FORM_FACTOR !== 'Small';
    }

    get isFilesHeader() {
    return (this.headerName || '').trim().toLowerCase() === 'files';
}

    
}
