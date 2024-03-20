import { LightningElement, api } from 'lwc';
import getACValues from '@salesforce/apex/AutoCompleteService.getACValues';
import autoCompleteMC from '@salesforce/messageChannel/AutoCompleteMessageChannel__c';
import { publish, createMessageContext, releaseMessageContext } from 'lightning/messageService';

export default class AutoComplete extends LightningElement {
    context = createMessageContext();
    initialized = false;
    values;
    @api label;
    @api placeholder;
    @api objectName;
    @api fieldNameValue;
    @api fieldNameKey;
    @api recordLimit;
    showLabel;
    @api acValue;

    constructor() {
        super();

        if (this.acValue === undefined) {
            this.acValue = '';
        }

        if (this.label) {
            this.showLabel = true;
        }
    }
 
    renderedCallback() {
        if (this.initialized) {
            return;
        }

        this.initialized = true;
        let listId = this.template.querySelector('datalist').id;
        this.template.querySelector("input").setAttribute("list", listId);
    }

    autoCompleteAction(event) {
        const val = event.target.value;
        this.values = null;
        this.acValue = val;

        if (val.length >= 2) {
            getACValues({ objectName: this.objectName,
                          fieldNameKey: this.fieldNameKey, fieldNameValue: this.fieldNameValue, 
                          searchValue: val, recordLimit: this.recordLimit
                         })
            .then(theResponse => {
                this.values = theResponse;
            });   
        } 
    }

    autoCompleteSelect(event) {
        const val = event.target.value;
        this.acValue = val;

        if (this.values && this.values.length) {
            for (let theValue of this.values) {
                if (theValue.value === val ) {
                    const message = {
                        recordId: theValue.key,
                        message : 'AutoComplete',
                        source: 'autoComplete.lwc',
                        recordData : { fieldLabel: this.label, fieldValue : theValue.value } 
                    };
           
                    publish (this.context, autoCompleteMC, message);                    
                    break;
                }
            }
        }
    }

    disconnectedCallback() {
        releaseMessageContext(this.context);
    }     
}