import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import { extend } from 'c/lodash';

import { collectionOperationQueryModel, collectionOperationService } from 'c/dataService';

export default class SlwcDriveOptimizeSettings extends LightningElement {
  _collectionOperations = [];
  @api
  get collectionOperations() {
    return this._collectionOperations;
  }
  set collectionOperations(value) {
    this._collectionOperations = value;

    this.getCollectionOperation();
  }

  @track showSpinner = true;
  @track collectionOperation;

  connectedCallback() {
    
  }

  disconnectedCallback() {
  }

  getCollectionOperation() {
    if (!this._collectionOperations || !this._collectionOperations.length) return;
    let collectionOperationId = this._collectionOperations[0].id;
    let query = new collectionOperationQueryModel();
    query.recordIds = [collectionOperationId];
    let service = new collectionOperationService();
    service.query(query)
    .then((result) => {
      this.collectionOperation = result[0];
    })
    .catch((error) => {console.log(error)})
    .finally(() => {this.showSpinner = false});
  }

  handleOnChange(event) {
    this.collectionOperation = extend(this.collectionOperation, event.detail);
  }

  handleSave() {
    this.showSpinner = true;
    let service = new collectionOperationService();
    service.save(this.collectionOperation)
    .then((result) => {
      const event = new ShowToastEvent({
        message: 'Optimization Setting was updated successfully.',
        variant: 'success',
        mode: 'dismissable'
      });
      this.dispatchEvent(event);
    })
    .catch((error) => {console.log(error)})
    .finally(() => {this.showSpinner = false});
  }
}