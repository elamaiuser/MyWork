import { LightningElement, track, api } from 'lwc';
import { classNames, getValueFromEvent, isNullOrEmpty } from 'c/slwcUtils';
import { activityService, collectionOperationService } from 'c/dataService';
import * as slwcDateUtils from 'c/slwcDateUtils';
import TIME_ZONE from '@salesforce/i18n/timeZone';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { cloneDeep } from 'c/lodash';

export default class SlwcActivityModal extends LightningElement {
  _isOpen = true;
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

  @api drive = null;
  @api activity = null;

  @track model = {};
  @track timezoneSidId = TIME_ZONE;
  @track showSpinner = false;
  @track errorMessages = [];

  get dateUtils() {
    return slwcDateUtils.getInstance({
      timezone: TIME_ZONE
    })
  }

  get modalHeader() {
    if(this.activity && this.activity.id) {
      return 'Edit Linked Activity';
    } else {
      return 'Create Linked Activity';
    }
  }

  get saveBtnDisabled() {
    return this.showSpinner;
  }

  get addressInputLabel() {
    return this.model.subtype === 'Travel' ? 'Departure Address' : 'Address';
  }

  get notesHelpText() {
    return this.model.subtype === 'Travel' ? 'Enter details for Overnight City, Arrival Address and other notes.' : null;
  }
  
  get notesRequired() {
    return this.model.subtype === 'Travel';
  }
  
  get subtypeControllingFieldValues() {
    return this.model.eventType ? [this.model.eventType] : []
  }

  get subtypeDisabled() {
    return !this.model.eventType;
  }

  get customClass() {
    return {
      modalClass: classNames('slds-modal slds-modal_medium', {
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
    this.init();
  } 

  showLoading = () => {
    this.showSpinner = true;
  }

  hideLoading = () => {
    this.showSpinner = false;
  }

  exceptionHandler = (error) => {
    console.log(error);
    if(error && error.message) {
        this.dispatchEvent(new ShowToastEvent({
            message: error.message,
            variant: 'error',
            mode: 'dismissable',
        }));
    }
  }

  init = () => {
    this.resetModel(); 
  }

  resetModel = () => {
    this.dataSaved = false;
    this.model = {
      address: null
    };

    if(this.activity) {
      this.model = cloneDeep(this.activity);
      this.model.address = this.model.address || null;
    }
  }

  handleOnChange(event) {
    event.stopPropagation();

    if(event.detail && event.detail.selection) {
      this.model[event.currentTarget.name] = event.detail.selection.id;
    } else {
      let value = getValueFromEvent(event);
      this.model[event.currentTarget.name] = value;
    }
  }

  handleSelectAddress(event) {
    if(!event || !event.detail || !event.detail.placeDetails) return;

    let placeDetails = event.detail.placeDetails;
    this.model.postalCode = placeDetails.addressComponents.postalCode;//HRP-13791
    this.model.address = placeDetails.formattedAddress;
    this.model.geoLocationLatitude = placeDetails.geometry && placeDetails.geometry.lat;
    this.model.geoLocationLongitude = placeDetails.geometry && placeDetails.geometry.lng;
  }

  handleCancel = () => {
    const closeEvent = new CustomEvent('close', {
      detail: {
        result: !!this.dataSaved
      }
    });
    this.dispatchEvent(closeEvent);
    this.isOpen = false;
  }

  validate() {
    this.errorMessages = [];

    const allValid = [
        ...this.template.querySelectorAll('lightning-input'), 
        ...this.template.querySelectorAll('lightning-textarea'),
        ...this.template.querySelectorAll('c-slwc-address-input'),
        ...this.template.querySelectorAll('c-slwc-picklist')]
        .reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);

    if(this.model.start && this.model.finish) {
      if(this.model.start >= this.model.finish) {
        this.errorMessages.push({
          message: 'Start must before End.'
        })
      }
    } 
    return allValid && !this.errorMessages.length;
  }

  handleSave = () => {
    if(!this.validate()) return;

    let modelToSave = {
      ...this.model,
      timezoneSidId: null,
      linkedDrivesId: this.drive ? this.drive.linkedDriveId : null,
      isGroupActivity: true,
      showOnCalendar: true
    }
    this.showLoading();
    let service = new collectionOperationService();
    service.getSkedRegionIdUsingTaxonomy({
      collectionOperationId: this.drive.collectionOperationId,
      postalCode: modelToSave.postalCode,
      start: modelToSave.start,
      finish: modelToSave.finish
    })
    .then(result => {
      if(!result || !result.returnedData) {
        this.dispatchEvent(new ShowToastEvent({
          message: 'Cannot find Skedulo region that matches the address timezone.',
          variant: 'error',
          mode: 'dismissable'
        }));
        return;
      }

      modelToSave.regionId = result.returnedData;
      modelToSave.collectionOperationId = this.drive.collectionOperationId;
      modelToSave.districtId = this.drive.districtId;
      let service = new activityService();
      return service.saveList([modelToSave])
      .then(() => {
        this.dataSaved = true;
        this.dispatchEvent(new ShowToastEvent({
          message: 'Created linked drive successfully.',
          variant: 'success',
          mode: 'dismissable'
        }));
        this.handleCancel();
      })
    })
    .catch(error => this.exceptionHandler(error))
    .finally(() => this.hideLoading());
  }
}