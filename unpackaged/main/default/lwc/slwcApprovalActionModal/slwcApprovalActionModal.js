import { LightningElement, track, api } from 'lwc';
import { approvalService, commonService, debugLogService } from 'c/dataService';
import { classNames, getValueFromEvent, isNullOrEmpty } from 'c/slwcUtils';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import * as autoMapper from 'c/autoMapper';

const FIELD_TYPE = {
  TEXT: 'text',
  PICKLIST: 'picklist',
  DATE: 'date',
  LOOKUP: 'lookup'
}

export default class SlwcApprovalActionModal extends LightningElement {
  _isOpen = false;
  @api
  get isOpen() {
    return this._isOpen;
  };
  set isOpen(value) {
    this._isOpen = value;
    this.init();
  }

  @api additionalFields = [];
  @api action = null;
  @api actionLabel = null;
  @api recordId = null;
  @api objectLabel = null;
  @api hideComments = false;

  @api hookBeforeSubmitApproveReject = null;

  @track model = {};
  @track showSpinner = false;
  @track dirty = false;
  @track transformedAdditionalFields = [];
  @track objectApiName = null;

  get title() {
    return `${this.actionLabel} ${this.objectLabel}`;
  }

  get confirmBtnLabel() {
    return this.actionLabel;
  }

  get customClass() {
    return {
      modalClass: classNames('slds-modal slds-modal_xx-small', {
        'slds-fade-in-open': this.isOpen
      }),
      headerClass: classNames('slds-modal__header'),
      footerClass: classNames('slds-modal__footer'),
      backdropClass: classNames('slds-backdrop', {
        'slds-backdrop_open': this.isOpen
      })
    }
  }
  
  get confirmBtnDisabled() {
    if(this.showSpinner) return true;
    return false;
  }

  showLoading = () => {
    this.showSpinner = true;
  }

  hideLoading = () => {
    this.showSpinner = false;
  }
  
  getRecordData = (recordId) => {
    let _commonService = new commonService();
    return _commonService.getSObjectName({
      recordId: recordId
    })
    .then(result => {
      this.objectApiName = result;

      let { service, queryModel } = _commonService.getServiceBySObjectName(result);
      queryModel.recordIds = [recordId];

      return service.query(queryModel)
    })
    .then(([result]) => {
      return result;
    })
  }

  init = () => {
    this.showLoading();
    this.getRecordData(this.recordId)
    .then((data) => {
      this.model = data;
      this.dirty = false;
      this.transformedAdditionalFields = this.additionalFields.filter(fieldSetting => {
        if(!fieldSetting.hideIf) {
          return true;
        } 

        return !fieldSetting.hideIf(this.model);
      }).map(fieldSetting => {
        return {
          ...fieldSetting,
          showText: fieldSetting.type === FIELD_TYPE.TEXT,
          showDate: fieldSetting.type === FIELD_TYPE.DATE,
          showLookup: fieldSetting.type === FIELD_TYPE.LOOKUP,
          showPicklist: fieldSetting.type === FIELD_TYPE.PICKLIST,
          defaultValue: this.model[fieldSetting.field]
        }
      })
    })
    .catch((error) => {
      new debugLogService().captureDebugLog(error, this.recordId);
      this.dispatchEvent(new ShowToastEvent({
        message: error.message,
        variant: 'error',
        mode: 'dismissable',
      }));
    })
    .finally(() => this.hideLoading());
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

  validate() {
    let allInputs = [
      ...this.template.querySelectorAll('lightning-input'), 
      ...this.template.querySelectorAll('lightning-combobox'),
      ...this.template.querySelectorAll('c-slwc-lookup')
    ];
    allInputs.forEach((inputCmp) => {
        inputCmp.reportValidity();
    });
    
    this.dirty = true;
    return this.transformedAdditionalFields.reduce((validSoFar, fieldSetting) => {
      if(fieldSetting.required) {
        validSoFar = validSoFar && !isNullOrEmpty(this.model[fieldSetting.field]);
      }
      return validSoFar;
    }, true);
  } 

  buildSuccessMessage() {
    let actionLabel = this.actionLabel.toLowerCase() + 'ed';
    actionLabel = actionLabel.replace(new RegExp('eed$'), 'ed');
    actionLabel = actionLabel.replace(new RegExp('yed$'), 'ied');
    return `${this.objectLabel} has been ${actionLabel} successfully.`;
  }

  buildAdditionalFieldsSObject() {
    let model = this.transformedAdditionalFields.reduce((result, fieldSetting) => {
      return {
        ...result,
        [fieldSetting.field]: this.model[fieldSetting.field]
      }
    }, {
      id: this.recordId
    });
    
    let sObjectWrapper = autoMapper.autoMapperInstance.mapToSObject(this.objectApiName, model);
    return sObjectWrapper.sObj;
  }

  handleConfirm = (event) => {
    if(!this.validate()) {
      const event = new ShowToastEvent({
        message: 'Please check all required fields.',
        variant: 'error',
        mode: 'dismissable'
      });
      this.dispatchEvent(event);
      return;
    }

    this.showLoading();
    Promise.resolve()
    .then(() => {
      const request = {
        recordId: this.recordId,
        comments: this.model.comments,
        sObj: this.buildAdditionalFieldsSObject(),
        action: this.action
      };

      if(this.hookBeforeSubmitApproveReject) {
        return this.hookBeforeSubmitApproveReject(request);
      } else {
        return request;
      }
    })
    .then((request) => {
      if(!request) throw 'stop';

      let service = new approvalService();
      return service.approveReject({request: request})
    })
    .then((result) => {
      const event = new ShowToastEvent({
        message: this.buildSuccessMessage(),
        variant: 'success',
        mode: 'dismissable'
      });
      this.dispatchEvent(event);

      const closeEvent = new CustomEvent('close', {
        detail: {
          result: true
        }
      });
      this.dispatchEvent(closeEvent);
      this.isOpen = false;  
      
      // refreshLightningPage();
    })
    .catch((error) => {
      if(error === 'stop') return;

      new debugLogService().captureDebugLog(error, this.recordId);
      this.dispatchEvent(new ShowToastEvent({
        message: error.message,
        variant: 'error',
        mode: 'dismissable',
      }));
    })
    .finally(() => this.hideLoading())
  }

  handleCancel = () => {
    const closeEvent = new CustomEvent('close', {
      detail: {
        result: false
      }
    });
    this.dispatchEvent(closeEvent);
    this.isOpen = false;
  }
}