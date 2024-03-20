import { LightningElement, track, wire, api } from 'lwc';
import { classNames, isNullOrEmpty } from 'c/slwcUtils';
import { getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { CurrentPageReference } from 'lightning/navigation';

export default class SlwcSelect extends LightningElement {
  @wire(CurrentPageReference) pageRef;

  @api name = null;
  @api label = null;
  @api id = null;
  @api options = [];
  @api variant = null;
  @api classes = null;
  @api readOnly = false;
  @api required = false;
  @api objectApiName;
  @api pickListfieldApiName;
  
  _selectedValue = null;
  @api
  get selectedValue() {
    return this._selectedValue;
  }
  set selectedValue(value) {
    this._selectedValue = value;
    this.setValue();
  }

  get selectElement() {
    return this.template.querySelector('.slds-select');
  }
  
  get showLabel() {
    return this.variant !== 'label-hidden';  
  }

  get customClass() {
    return {
      selectContainer: classNames('slds-select_container', this.classes)
    }
  }

  @api reportValidity() {
    const valid = this.checkValidity();
    [
      ...this.template.querySelectorAll('.slds-form-element'),
      ...this.template.querySelectorAll('.errors')
    ].forEach((inputField) => {
      if (valid) {
        inputField.classList.remove('slds-has-error');
      } else {
        inputField.classList.add('slds-has-error');
      }
    });
  }

  @api checkValidity() {
    if (!this.required) return true;
    return !isNullOrEmpty(this.selectedValue);
  }
  
  @wire(getObjectInfo, { objectApiName: '$objectApiName' })
  getRecordTypeId({ error, data }) {
      if (data) {
          this.record = data;
          this.error = undefined;
          if(this.recordTypeId === undefined){
              this.recordTypeId = this.record.defaultRecordTypeId;
          }
      } else if (error) {
          this.error = error;
          this.record = undefined;
          console.log("this.error",this.error);
      }
  }
                   
  @wire(getPicklistValuesByRecordType, { recordTypeId: '$recordTypeId', objectApiName: '$objectApiName' })
  wiredOptions({ error, data }) {
      if (data) {
          this.record = data;
          this.error = undefined;
          
          if(this.record.picklistFieldValues[this.pickListfieldApiName] !== undefined) {

              let tempOptions = [];
              let temp2Options = this.record.picklistFieldValues[this.pickListfieldApiName].values;
              temp2Options.forEach(opt => tempOptions.push(opt));

              this.options = tempOptions;
          }
          
          if(this.selectedValue === '' || this.selectedValue === undefined || this.selectedValue === null) {
              this.selectedValue = '';
          } else {
              this.selectedValue = this.options.find(listItem => listItem.value === this.selectedValue).value;
          }
          this.setValue();
      } else if (error) {
          this.error = error;
          this.record = undefined;
      }
  }
  renderedCallback() {
    this.setValue();
  }

  setValue() {
    if(this.selectElement) {
      this.selectElement.value = this.selectedValue; 
    }
  }

  handleOnChange(event) {
    let selectedValue = event.currentTarget.value;
    
    const pickValueChangeEvent = new CustomEvent('change', {
        detail: { selectedValue },
    });
    this.dispatchEvent(pickValueChangeEvent);

    setTimeout(() => {
      this.reportValidity();
    })
  }
}