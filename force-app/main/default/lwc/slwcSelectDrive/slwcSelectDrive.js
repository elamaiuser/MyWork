import { LightningElement, track, api, wire } from 'lwc';
import { getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { CurrentPageReference } from 'lightning/navigation';
import { registerListener, unregisterAllListeners, fireEvent } from 'c/pubsub';
import { cloneDeep, isBoolean, isEmpty } from 'c/lodash';
import * as slwcUtils from 'c/slwcUtils';

export default class SlwcSelectDrive extends LightningElement {
    @wire(CurrentPageReference) pageRef;
    
    @track showOptions = false;
    @track dependentPickListMap = {};

    @track _pickListValues = [];
    @api
    get pickListValues() {
        return this._pickListValues;
    }
    set pickListValues(value) {
        this._pickListValues = cloneDeep(value);
    }

    @track clonedPickListValues = [];
    @track filters = {
        searchString: ''
    }

    _defaultValues = [];
    @api
    get defaultValues() {
        return this._defaultValues;
    }
    set defaultValues(value) {
        this._defaultValues = value;
        this.setSelectedValues(this._defaultValues);
    }

    @api selectedByDefault = false;
    @api name;
    @api objectApiName;
    @api fieldApiName;
    @api label;
    @api uniqueKey;
    @api singleSelect = false;
    @api showPills = false;
    @api controllingFieldApi;

    _controllingFieldValues;
    @api
    get controllingFieldValues() {
        return this._controllingFieldValue;
    }
    set controllingFieldValues(value) {
        this._controllingFieldValue = value;
        this.pickListValues = this.generateOptions(true);

        if(this.isInitialized) {
            this.handlePicklistChange();
        }
    }

    isInitialized = false;
    isDependentPicklist = false;
    recordTypeId;

    get selectionLabel() {
        if (!this.selectedValues || this.selectedValues.length == 0) {
            return `Select Option${this.singleSelect ? '' : '(s)'}`;
        }
        else if (this.selectedValues.length == 1) {
            return this.selectedValues[0].label;
        }
        else if (this.selectedValues.length == this.pickListValues.length) {
            return 'All options selected';
        }
        else {
            return this.selectedValues.length + ' options selected';
        }
    }

    get selectedValues() {
        return this.pickListValues.filter(item => item.selected);
    }

    closeDropdown = () => {
        this.toggleOptions(false);
    }

    toggleOptions(force) {
        setTimeout(() => {
            this.showOptions = isBoolean(force) ? force : !this.showOptions;
            this.clonedPickListValues = cloneDeep(this.pickListValues);
            if(this.showOptions) {
                this.filters.searchString = '';
                this.filterPicklistValues();
            }
        })
    }

    @wire(getObjectInfo, { objectApiName: '$objectApiName' })
    getRecordTypeId({ error, data }) {
        if (data) {
            if (this.recordTypeId === undefined) {
                this.recordTypeId = data.defaultRecordTypeId;
            }
        } else if (error) {
            console.log("error",error) ;
        }
    }
    
    @wire(getPicklistValuesByRecordType, {recordTypeId: '$recordTypeId', objectApiName: '$objectApiName'})
    wiredOptions({ error, data }) {
        if (data) {
            if (data.picklistFieldValues[this.fieldApiName]) {
                this.dependentPickListMap = {};
                let controllerValuesMap = data.picklistFieldValues[this.fieldApiName].controllerValues || {};
                this.isDependentPicklist = !isEmpty(controllerValuesMap);
                if(!this.isDependentPicklist) {
                    controllerValuesMap = {
                        DEFAULT: 0
                    }
                }

                Object.entries(controllerValuesMap).forEach(([key, value]) =>  {
                    if(!this.dependentPickListMap[key]) {
                        this.dependentPickListMap[key] = [];
                    }

                    const picklistValues = data.picklistFieldValues[this.fieldApiName].values;
                    picklistValues.forEach(item => {
                        let pickListValue = {
                            label: item.label,
                            value: item.value,
                            validFor: item.validFor || [],
                            selected: false
                        };
                        
                        if (this.defaultValues ) {
                            pickListValue.selected = this.defaultValues;
                        }
                        else if (this.selectedByDefault) {
                            pickListValue.selected = true;
                        }

                        if(this.isDependentPicklist) {
                            if (pickListValue.validFor.includes(value)) {
                                this.dependentPickListMap[key].push(pickListValue);
                            }
                        } else {
                            this.dependentPickListMap['DEFAULT'].push(pickListValue);
                        }
                        
                    });
                });
                
                this.pickListValues = this.generateOptions();

                if (this.selectedByDefault) {
                    this.handlePicklistChange();
                }

                this.isInitialized = true;
            }
        } else if (error) {
            console.log("error", error);
        }
    }

    generateOptions(restoreSelectedValues) {
        if(!this.isDependentPicklist) {
            return this.dependentPickListMap['DEFAULT'] || [];
        }

        let lastSelectedValues = cloneDeep(this.selectedValues);
        let pickListValues = [];
        (this.controllingFieldValues || []).forEach((controllingValue) => {
            let picklistFieldValues = this.dependentPickListMap[controllingValue.value || controllingValue] || [];
            picklistFieldValues.forEach((item) => {
                if(restoreSelectedValues) {
                    item.selected = !!lastSelectedValues.find(temp => temp.value === item.value);
                }
                const isExisted = pickListValues.find(temp => temp.value === item.value);
                if(!isExisted) {
                    pickListValues.push(item);                    
                }
            });
        });

        return pickListValues;
    }

    handleRemove(event) {
        this.clonedPickListValues.forEach(item => {
            if (item.value == event.currentTarget.dataset.item) {
                item.selected = false;
            }
        });
    }
    
    handleSelected(event) {
        let selectedValue = event.currentTarget.dataset.item;
        setTimeout(() => {
            this.clonedPickListValues.forEach(item => {
                if (item.value === selectedValue) {
                    item.selected = this.singleSelect || !item.selected;
                } 
            })
            
            this.handlePicklistChange(selectedValue);
            this.pickListValues = this.clonedPickListValues;
            this.closeDropdown();
        })
    }

    setSelectedValues(selectedValues ) {
        const selectedId = selectedValues;
        this.pickListValues.forEach(item => {
            item.selected = (selectedId == item.value);
        });
    }

    handlePicklistChange(selectedValue) {
        let key = this.uniqueKey;
        const pickValuesChangeEvent = new CustomEvent('picklistchange', {
            detail: { value:selectedValue, key }
        });
        this.dispatchEvent(pickValuesChangeEvent);
    }

    filterPicklistValues() {
        let searchString = (this.filters.searchString || '').toLowerCase();
        
        this.filteredPicklistValues = (this.clonedPickListValues || []).filter(item => {
            return item.label.toLowerCase().includes(searchString);
        })
    }

    handleSearch(event) {
        event.stopPropagation(); //must have

        let targetValue = slwcUtils.getValueFromEvent(event);

        clearTimeout(this.timeoutId); // no-op if invalid id
        this.timeoutId = setTimeout(() => {
            this.filters.searchString = targetValue;
            this.filterPicklistValues();
        }, 500);
    }
}