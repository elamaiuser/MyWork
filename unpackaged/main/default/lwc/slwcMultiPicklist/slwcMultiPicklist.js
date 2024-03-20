import { LightningElement, track, api, wire } from 'lwc';
import { getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { CurrentPageReference } from 'lightning/navigation';
import { cloneDeep, isBoolean } from 'c/lodash';
import * as slwcUtils from 'c/slwcUtils';
import { dataService } from 'c/dataService';

export default class SlwcMultiPicklist extends LightningElement {
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
    @api dependentFieldApiName;
    @api label;
    @api uniqueKey;
    @api allowedValues = [];
    @api excludedValues = [];
    @api singleSelect = false;
    @api maxSelections;
    @api showPills = false;
    @api disabled = false;
    @api required = false;
    @api isReadonly = false;

    _controllingFieldValues;
    @api
    get controllingFieldValues() {
        return this._controllingFieldValues;
    }
    set controllingFieldValues(value) {
        this._controllingFieldValues = value;
        this.pickListValues = this.generateOptions(true);

        if(this.isInitialized) {
            this.handlePicklistChange();
        }
    }

    isInitialized = false;
    isDependentPicklist = false;
    recordTypeId;

    @api reportValidity() {
        const valid = this.checkValidity();
        [
            ...this.template.querySelectorAll('.multipicklist-placeholder'),
            ...this.template.querySelectorAll('.errors')
        ].forEach((inputField) => {
            if(valid) {
                inputField.classList.remove('slds-has-error');
            } else {
                inputField.classList.add('slds-has-error');
            }
        });
    }

    @api checkValidity() {
        if(!this.required) return true;
        return this.selectedValues && this.selectedValues.length;
    }

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

    get canToggleOptions() {
        if (this.isReadonly) {
            return false;
        }

        if(!this.isDependentPicklist) return true;

        return this.controllingFieldValues && this.controllingFieldValues.length;
    }

    get maxSelectedValues() {
        if(this.singleSelect) return 1;
        if(this.maxSelections) return this.maxSelections;
        return Number.MAX_VALUE;
    }

    get canSelectAll() {
        if(this.singleSelect) return false;
        if(this.maxSelections) return false;
        return true;
    }

    closeDropdown = () => {
        this.toggleOptions(false);
    }

    toggleOptions(force) {
        if(!this.canToggleOptions) return;
        
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
                    description: item.description,
                    selected: false
                };
                
                if (this.defaultValues && this.defaultValues.length > 0) {
                    pickListValue.selected = this.defaultValues.includes(pickListValue.value);
                }
                else if (this.selectedByDefault) {
                    pickListValue.selected = true;
                }
                return pickListValue;
            });

            this.dependentPickListMap.DEFAULT = picklistValues;
            
            Object.keys(mapDependentOptions).forEach(item => {
                this.dependentPickListMap[item] = picklistValues.filter(picklistValue => mapDependentOptions[item].includes(picklistValue.value));
            });

            this.pickListValues = this.generateOptions();
            this.isInitialized = true;

            if (this.selectedByDefault) {
                setTimeout(() => {
                    this.handlePicklistChange();
                })
            }
        });
    }

    generateOptions(restoreSelectedValues) {
        if (!this.isDependentPicklist) {
            return this.dependentPickListMap['DEFAULT'] || [];
        }

        let lastSelectedValues = cloneDeep(this.selectedValues);
        let pickListValues = [];
        (this.controllingFieldValues || []).forEach((controllingValue) => {
            let picklistFieldValues = this.dependentPickListMap[controllingValue.value || controllingValue] || [];
            picklistFieldValues.forEach((item) => {
                if (restoreSelectedValues) {
                    item.selected = !!lastSelectedValues.find(temp => temp.value === item.value);
                }
                const isExisted = pickListValues.find(temp => temp.value === item.value);
                if (!isExisted) {
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
        if(this.disabled) return;
        
        let selectedValue = event.currentTarget.dataset.item;
        setTimeout(() => {
            this.clonedPickListValues.forEach(item => {
                if (item.value === selectedValue) {
                    if(this.singleSelect) {
                        item.selected = true;
                    } else {
                        if(item.selected) {
                            item.selected = false;
                        } else {
                            const currentNumberSelectedValues = this.clonedPickListValues.filter(item => item.selected).length;
                            if(currentNumberSelectedValues < this.maxSelectedValues) {
                                item.selected = true;
                            }
                        }
                    }
                } else {
                    if(this.singleSelect) {
                        item.selected = false;
                    }
                }
            })
        })
    }

    setSelectedValues(selectedValues = []) {
        const selectedIds = selectedValues.map(item => item.value || item);
        this.pickListValues.forEach(item => {
            item.selected = selectedIds.includes(item.value);
        });
    }

    handleSelectAll() {
        this.clonedPickListValues.forEach(item => {
            item.selected = true;
        });
    }

    handleSelectNone() {
        this.clonedPickListValues.forEach(item => {
            item.selected = false;
        });
    }

    handleDone(event) {
        this.pickListValues = cloneDeep(this.clonedPickListValues);
        this.closeDropdown();
        this.handlePicklistChange();
        this.reportValidity();
    }

    handlePicklistChange() {
        let key = this.uniqueKey;
        let selectedValues = cloneDeep(this.selectedValues);
        const pickValuesChangeEvent = new CustomEvent('picklistchange', {
            detail: { selectedValues, key }
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