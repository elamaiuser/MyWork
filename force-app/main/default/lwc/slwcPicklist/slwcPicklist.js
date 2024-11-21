import { LightningElement, track, wire, api } from 'lwc';
import { getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { CurrentPageReference } from 'lightning/navigation';
import { fireEvent } from 'c/pubsub';
import { dataService } from 'c/dataService';

export default class SlwcPicklist extends LightningElement {
    
    @wire(CurrentPageReference) pageRef;

    @api required = false;
    @api disabled = false;
    @api name;
    @api objectApiName;
    @api pickListfieldApiName;
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
        
        const service = new dataService();
        Promise.all([
            service.getPicklistOptions({
                objectApiName: this.objectApiName,
                fieldApiName: this.pickListfieldApiName
            })
        ])
        .then(([picklistOptionsResult = {}]) => {
            let picklistValues = picklistOptionsResult.returnedData || [];
            let tempOptions = [{ label: '--None--', value: "" }];
            let temp2Options = picklistValues;

            if(this.allowedValues.length) {
                temp2Options = temp2Options.filter(opt => {
                    return this.allowedValues.includes(opt.value);
                })
            }  

            if(this.excludedValues.length) {
                temp2Options = temp2Options.filter(opt => {
                    return !this.excludedValues.includes(opt.value);
                })
            }
            
            temp2Options.forEach(opt => tempOptions.push(opt));

            this.options = tempOptions;

            if(this.selectedValue === '' || this.selectedValue === undefined || this.selectedValue === null) {
                this.value = { label: '--None--', value: "" }.value;
            } else {
                this.value = this.options.find(listItem => listItem.value === this.selectedValue).value;
            }
        });
    }


    handleChange(event) {
        let tempValue = event.target.value;
        let selectedValue = tempValue;
        let key = this.uniqueKey;

        const pickValueChangeEvent = new CustomEvent('picklistchange', {
            detail: { selectedValue, key },
        });
        this.dispatchEvent(pickValueChangeEvent);

        let eventValues = {selValue : selectedValue, uniqueFieldKey: `${this.pickListfieldApiName}${this.uniqueKey}`};
        fireEvent(this.pageRef, 'controllingValue', eventValues);
    }

}