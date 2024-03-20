import { LightningElement, track, api } from 'lwc';
import { classNames } from 'c/slwcUtils';

export default class SlwcConfirmImpactedDrivesModal extends LightningElement {
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
  
  @api impactedDrives = [];

  @track showSpinner = false;
  @track tableData = [];

  get totalRecords() {
    return this.tableData.length || 0;
  }

  get columns() {
    let results = [];
    results.push({label: 'Drive Name', fieldName: 'recordPageUrl', initialWidth: 300, type: 'url', hideDefaultActions: true, wrapText: true, typeAttributes: {label: { fieldName: 'name' }, target: '_blank' } } );
    results.push({label: 'Impacts', fieldName: 'impacts', type: 'text', hideDefaultActions: true, wrapText: true } );
    return results;
  }

  get customClass() {
    return {
      modalClass: classNames('slds-modal', {
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
    this.tableData = this.impactedDrives.map(drive => {
      return {
        ...drive,
        recordPageUrl: '/' + drive.id,
        impacts: drive.impactedVehicleMessages && drive.impactedVehicleMessages.length ? drive.impactedVehicleMessages[0] : null
      }
    })
  }

  handleCancel = () => {
    const closeEvent = new CustomEvent('close', {
      detail: {
      }
    });
    this.dispatchEvent(closeEvent);
    this.isOpen = false;
  }

  handleSave = () => {
    const saveEvent = new CustomEvent('save', {
      detail: {
        drives: this.impactedDrives
      }
    });
    this.dispatchEvent(saveEvent);
    this.isOpen = false;
  }
}