import { LightningElement, track, wire, api } from 'lwc';
import { getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { CurrentPageReference } from 'lightning/navigation';
import { fireEvent } from 'c/pubsub';
import { isEmpty } from 'c/lodash';
import { dataService } from 'c/dataService';

export default class SlwcDependentPicklist extends LightningElement {
    
    @wire(CurrentPageReference) pageRef;
    
    @track dependentPickListMap = {};

    @api required = false;
    @api disabled = false;
    @api name;
    @api objectApiName;
    @api fieldApiName;
    @api dependentFieldApiName;
    @api label;
    @api variant;
    @api uniqueKey;
    @api allowedValues = [];
    @api excludedValues = [];
    
    @track value;
    recordTypeIdValue;

    @track options = [
        { label: '--None--', value: "" }
    ];
    
    @api reportValidity() {
        [
            ...this.template.querySelectorAll('lightning-combobox')
        ].forEach((inputField) => {
            inputField.reportValidity();
        });
    }

    @api checkValidity() {
        return [
            ...this.template.querySelectorAll('lightning-combobox'),
        ].reduce((validSoFar, inputField) => {
            return validSoFar && inputField.checkValidity();
        }, true);
    }
    
    @api 
    get recordTypeId() {
        return this.recordTypeIdValue;
    }
    set recordTypeId(value) {
        this.recordTypeIdValue = value;
    }

    _dirty = false;
    @api 
    get dirty() {
        return this._dirty;
    }
    set dirty(value) {
        this._dirty = !!value;
        
        if(this._dirty) {
            const element = this.template.querySelector('lightning-combobox');
            if(element) {
                element.reportValidity();
            }
        }
    }

    @api 
    get selectedValue() {
        return this.value;
    }
    set selectedValue(val) {
        if (val === '' || val === undefined || val === null)
            this.value = { label: '--None--', value: "" }.value;
        else
            this.value = val;
    }
         
    _controllingFieldValues;
    @api
    get controllingFieldValues() {
        return this._controllingFieldValues;
    }
    set controllingFieldValues(value) {
        this._controllingFieldValues = value;
        this.options = this.generateOptions();

        if(this.isInitialized) {
            this.handleChange({
                target: {
                    value: this.value
                }
            });
        }
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
        this.record = data;
        this.error = error;

        if(!data) return;

        this.isDependentPicklist = !!this.dependentFieldApiName;
        const service = new dataService();
        Promise.all([
            service.getPicklistOptions({
                objectApiName: this.objectApiName,
                fieldApiName: this.fieldApiName
            }),
            this.isDependentPicklist ? 
                service.getMapDependentOptions({
                    objectApiName: this.objectApiName,
                    controllingFieldApiName: this.dependentFieldApiName,
                    dependentFieldApiName: this.fieldApiName
                }) :
                Promise.resolve()
        ])
        .then(([picklistOptionsResult = {}, mapDependentOptionsResult = {}]) => {
            let picklistValues = picklistOptionsResult.returnedData || [];
            const mapDependentOptions = mapDependentOptionsResult.returnedData || {};

            this.dependentPickListMap = {
                DEFAULT: []
            };
          
            if (this.allowedValues.length) {
                picklistValues = picklistValues.filter(opt => {
                    return this.allowedValues.includes(opt.value);
                });
            }  

            if (this.excludedValues.length) {
                picklistValues = picklistValues.filter(opt => {
                    return !this.excludedValues.includes(opt.value);
                });
            }

            picklistValues = picklistValues.map(item => {
                let pickListValue = {
                    label: item.label,
                    value: item.value,
                };
                return pickListValue;
            });

            this.dependentPickListMap.DEFAULT = picklistValues;
            
            Object.keys(mapDependentOptions).forEach(item => {
                this.dependentPickListMap[item] = picklistValues.filter(picklistValue => mapDependentOptions[item].includes(picklistValue.value));
            });

            this.options = this.generateOptions();

            if(this.selectedValue === '' || this.selectedValue === undefined || this.selectedValue === null) {
                this.value = { label: '--None--', value: "" }.value;
            } else {
                this.value = this.options.find(listItem => listItem.value === this.selectedValue).value;
            }

            this.isInitialized = true;
        });
    }

    generateOptions() {
        if(!this.isDependentPicklist) {
            return this.dependentPickListMap['DEFAULT'] || [];
        }

        let pickListValues = [{ label: '--None--', value: "" }];
        (this.controllingFieldValues || []).forEach((controllingValue) => {
            let picklistFieldValues = this.dependentPickListMap[controllingValue.value || controllingValue] || [];
            picklistFieldValues.forEach((item) => {
                const isExisted = pickListValues.find(temp => temp.value === item.value);
                if(!isExisted) {
                    pickListValues.push(item);                    
                }
            });
        });

        return pickListValues;
    }
    

    handleChange(event) {
        let tempValue = event.target.value;
        let selectedValue = (this.options.find(option => option.value === tempValue) || {}).value;
        let key = this.uniqueKey;

        const pickValueChangeEvent = new CustomEvent('picklistchange', {
            detail: { selectedValue, key },
        });
        this.dispatchEvent(pickValueChangeEvent);

        let eventValues = {selValue : selectedValue, uniqueFieldKey: `${this.fieldApiName}${this.uniqueKey}`};
        fireEvent(this.pageRef, 'controllingValue', eventValues);
    }

}