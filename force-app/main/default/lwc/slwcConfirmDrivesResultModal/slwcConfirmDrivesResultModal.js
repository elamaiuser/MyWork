import { LightningElement, track, api } from 'lwc';
import { classNames } from 'c/slwcUtils';
import { keyBy, orderBy } from 'c/lodash';

export default class SlwcConfirmDrivesResultModal extends LightningElement {
  _isOpen = false;
  @api
  get isOpen() {
    return this._isOpen;
  };
  set isOpen(value) {
    this._isOpen = value;

    if(this._isOpen) {
      this.init();
    }
  }
  
  @api confirmDrivesResult = [];

  @track showSpinner = false;
  @track tableData = [];

  get totalRecords() {
    return this.tableData.length || 0;
  }

  get columns() {
    let columns = [];
    columns.push({label: 'Drive Name', fieldName: 'recordPageUrl', initialWidth: 300, type: 'url', hideDefaultActions: true, wrapText: true, typeAttributes: {label: { fieldName: 'name' }, target: '_blank' } } );
    columns.push({label: 'Drive UFID', fieldName: 'ufid', type: 'text', hideDefaultActions: true, wrapText: true } );
    columns.push({label: 'Drive Date', fieldName: 'driveDate', type: 'date-local', typeAttributes: { year: 'numeric', month: 'short', day: '2-digit' }, hideDefaultActions: true, wrapText: true } );
    columns.push({label: 'Start Time', fieldName: 'startTime', type: 'time', hideDefaultActions: true, wrapText: true });
    columns.push({label: 'End Time', fieldName: 'endTime', type: 'time', hideDefaultActions: true, wrapText: true });
    columns.push({label: 'Result', fieldName: 'message', initialWidth: 350, type: 'text', hideDefaultActions: true, wrapText: true } );
    return columns;
  }

  get customClass() {
    return {
      modalClass: classNames('slds-modal slds-modal_large', {
        'slds-fade-in-open': this.isOpen
      }),
      headerClass: classNames('slds-modal__header'),
      footerClass: classNames('slds-modal__footer'),
      backdropClass: classNames('slds-backdrop', {
        'slds-backdrop_open': this.isOpen
      })
    }
  }

  connectedCallback() {
  } 

  init = () => {
    this.tableData = orderBy(this.confirmDrivesResult.map(confirmResult => {
      return {
        ...confirmResult.drive,
        recordPageUrl: '/' + confirmResult.drive.id,
        message: confirmResult.message
      }
    }), ['driveDate', 'startTime'], ['asc', 'asc'])
  }

  handleCancel = () => {
    const closeEvent = new CustomEvent('close', {
      detail: {
      }
    });
    this.dispatchEvent(closeEvent);
    this.isOpen = false;
  }
}