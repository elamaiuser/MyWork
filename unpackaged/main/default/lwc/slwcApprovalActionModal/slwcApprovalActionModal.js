import { LightningElement, track, api } from 'lwc';
import { approvalService, commonService, debugLogService } from 'c/dataService';
import { classNames, getValueFromEvent, isNullOrEmpty } from 'c/slwcUtils';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import * as autoMapper from 'c/autoMapper';
import { FIELD_TYPE } from 'c/slwcConstants';

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
  @track errorMessages = [];

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
      this.transformedAdditionalFields = this.additionalFields.map(fieldSetting => {
        return {
          ...fieldSetting,
          show: !fieldSetting.hideIf || !fieldSetting.hideIf(this.model),
          showText: fieldSetting.type === FIELD_TYPE.TEXT,
          showNumber: fieldSetting.type === FIELD_TYPE.NUMBER,
          showDate: fieldSetting.type === FIELD_TYPE.DATE,
          showLookup: fieldSetting.type === FIELD_TYPE.LOOKUP,
          showPicklist: fieldSetting.type === FIELD_TYPE.PICKLIST,
          showMultiPicklist: fieldSetting.type === FIELD_TYPE.MULTIPICKLIST,
          defaultValue: fieldSetting.type === FIELD_TYPE.MULTIPICKLIST && this.model[fieldSetting.field] ? this.model[fieldSetting.field].split(';') : this.model[fieldSetting.field],
          required: typeof fieldSetting.required == 'function' ? fieldSetting.required(this.model) : fieldSetting.required,
          readonly: typeof fieldSetting.readonly == 'function' ? fieldSetting.readonly(this.model) : fieldSetting.readonly
        }
      })
      this.initControllingFieldValues();
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

  initControllingFieldValues() {
    this.transformedAdditionalFields.map(fieldSetting => {
      if (fieldSetting.dependentFieldApiName) {
        const controllingFieldSetting = this.transformedAdditionalFields.find(setting => setting.picklistFieldApiName === fieldSetting.dependentFieldApiName || setting.multiPicklistFieldApiName === fieldSetting.dependentFieldApiName);
        if (controllingFieldSetting) {
          fieldSetting.controllingFieldValues = !Array.isArray(controllingFieldSetting.defaultValue) ? (controllingFieldSetting.defaultValue ? [controllingFieldSetting.defaultValue] : []) : controllingFieldSetting.defaultValue;
        }
      }
    });
  }

  handleOnChange(event) {
    event.stopPropagation();

    if(event.detail && event.detail.selection) {
      this.model[event.currentTarget.name] = event.detail.selection.id;
    } else {
      let value = getValueFromEvent(event);
      this.model[event.currentTarget.name] = value;
    }

    for (let fieldSetting of this.transformedAdditionalFields) {
      if (fieldSetting.depends && !fieldSetting.depends(this.model)) {
        this.model[fieldSetting.field] = null;
      }
    }

    this.refreshInputVisibility();
    this.refreshControllingFieldValues(event);
    this.refreshAddtionalFieldsRequiredStatus();
  }

  refreshInputVisibility() {
    this.transformedAdditionalFields = this.transformedAdditionalFields.map(fieldSetting => {
      fieldSetting.show = !fieldSetting.hideIf || !fieldSetting.hideIf(this.model);
      return fieldSetting;
    });
  }

  refreshControllingFieldValues(event) {
    const controllingFieldSetting = this.transformedAdditionalFields.find(fieldSetting => fieldSetting.field === event.currentTarget.name && [FIELD_TYPE.PICKLIST, FIELD_TYPE.MULTIPICKLIST].includes(fieldSetting.type));
    if (controllingFieldSetting) {
      let controlledFieldSetting = this.transformedAdditionalFields.find(
        fieldSetting => [FIELD_TYPE.PICKLIST, FIELD_TYPE.MULTIPICKLIST].includes(fieldSetting.type) && fieldSetting.dependentFieldApiName
        && (fieldSetting.dependentFieldApiName === controllingFieldSetting.picklistFieldApiName || 
        fieldSetting.dependentFieldApiName === controllingFieldSetting.multiPicklistFieldApiName)
      );

      if (controlledFieldSetting) {
        const value = getValueFromEvent(event);
        controlledFieldSetting.controllingFieldValues = value ? [value] : [];

        this.transformedAdditionalFields = [...this.transformedAdditionalFields];
      }
    }
  }

  refreshAddtionalFieldsRequiredStatus() {
    const fieldsNeedReportValidity = [];
    this.additionalFields.forEach(fieldSetting => {
      if (typeof fieldSetting.required == 'function') {
        const transformedFieldSetting = this.transformedAdditionalFields.find(setting => setting.field === fieldSetting.field);
        if (transformedFieldSetting) {
          const isRequired = fieldSetting.required(this.model);

          // Need to refresh validatiy to clear required error for fields that turns to non-required.
          if (transformedFieldSetting.required !== isRequired && !isRequired) {
            fieldsNeedReportValidity.push(fieldSetting.field);
          }

          transformedFieldSetting.required = isRequired;
        }
      }
    });

    if (fieldsNeedReportValidity.length > 0) {
      // Need to set timeout as work around to make the reporting validity happens after data binding completed and input's required state updated on DOM
      setTimeout(() => {
        fieldsNeedReportValidity.forEach((field) => {
           const cmp = this.template.querySelector(`lightning-input[data-name="${field}"]`);
           if (cmp) {
            cmp.reportValidity();
           }
        });
      }, 0);
    }
  }

  validate() {
    this.errorMessages = [];

    let allInputs = [
      ...this.template.querySelectorAll('lightning-input'), 
      ...this.template.querySelectorAll('lightning-combobox'),
      ...this.template.querySelectorAll('c-slwc-lookup'),
      ...this.template.querySelectorAll('c-slwc-multi-picklist')
    ];
    
    this.dirty = true;

    const allRequiredFieldsValid = this.transformedAdditionalFields.reduce((validSoFar, fieldSetting) => {
      if((!fieldSetting.hideIf || !fieldSetting.hideIf(this.model)) && ((typeof fieldSetting.required == 'function' && fieldSetting.required(this.model))
        || fieldSetting.required)
      ) {
        validSoFar = validSoFar && !isNullOrEmpty(this.model[fieldSetting.field]);
      }
      return validSoFar;
    }, true);

    if (!allRequiredFieldsValid) {
      this.errorMessages.push({
        message: "Please check all required fields."
      });
    }

    return !this.errorMessages.length && allInputs.reduce((validSoFar, inputField) => {
      inputField.reportValidity();
      return validSoFar && inputField.checkValidity();
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
    if(this.validate()) {
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