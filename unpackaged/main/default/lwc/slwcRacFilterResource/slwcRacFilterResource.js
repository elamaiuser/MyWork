import {
    LightningElement,
    track,
    api
} from 'lwc';
import {
    classNames
} from 'c/slwcUtils';
import {
    cloneDeep,
} from 'c/lodash';
import * as slwcUtils from 'c/slwcUtils';

export default class SlwcRacFilterResource extends LightningElement {
    @api container;
    @api singleSelect = false;
    @api variant;
    @track _defaultValues = {
        onCall: false,
        selectedResourcesTag: [],
        queryText: ''
    };
    @api
    get defaultValues() {
        return this._defaultValues;
    }
    set defaultValues(value) {
        this._defaultValues = value || this._defaultValues;
    }

    @track filterPopverState = {
        onCall: false,
        selectedResourcesTag: [],
        queryText: ''
    }
    @track isFilter = false;
    @track clonedFilterPopverState = cloneDeep(this.filterPopverState);
    @api resourceTagsOption = []

    @track showFilterPopover = false;
    @track filterPopoverPosition = null;
    @track resourceTypesOption =[
        {
            value: 'Person',
            label: 'Person'
        },
        {
            value: 'Asset',
            label: 'Asset'
        },
    ]
    connectedCallback() {
        this.initDefaultValues();
    }

    get picklistElement() {
        return this.template.querySelector('.slds-button-group');
    }

    get picklistElementPosition() {
        if (!this.picklistElement) return null;
        return this.picklistElement.getBoundingClientRect();
    }

    get customClass() {
        return {
            filterPopover: classNames('slds-popover slds-popover_panel slds-nubbin_top-left filter-filters__popover', {
                'slds-fade-in-open': this.showFilterPopover
            }),
            filterPopoverBackdrop: classNames('slds-backdrop', {
                'slds-backdrop--open': this.showFilterPopover
            })
        }
    }

    get customStyle() {
        return {
            filterPopover: this.filterPopoverPosition ? [
                `top: ${this.filterPopoverPosition.top}px`,
                `left: ${this.filterPopoverPosition.left}px`
            ].join(';') : '',
        }
    }

    get filterButtonClass() {
        return this.isFilter ? 'color: #1d92d2' :''
    }

    initDefaultValues = () => {
        this.filterPopverState.selectedResourcesTag = cloneDeep(this.resourceTagsOption.filter(item => {
            return !!this.defaultValues.selectedResourcesTag.find(selected => selected.value === item.value);
        }))
    }

    setTeritotiesPopoverPosition = () => {
        if (!this.picklistElement) return;

        const picklistPosition = this.picklistElementPosition;
        this.filterPopoverPosition = {
            top: picklistPosition.y + picklistPosition.height,
            left:  picklistPosition.x - 13
        }
    }

    openFilterPopover = () => {
        this.showFilterPopover = true;
        this.initDefaultValues();
        this.setTeritotiesPopoverPosition();

        this.clonedFilterPopverState = cloneDeep(this.filterPopverState);
    }

    closeFilterPopover = () => {
        this.showFilterPopover = false;
    }


    applyFilter = () => {
        this.sendData()
        this.isFilter = this.clonedFilterPopverState.selectedResourcesTag.length > 0 || this.clonedFilterPopverState.onCall;
        this.closeFilterPopover();
    }

    handleResourceTagChanged = (event) => {
        this.clonedFilterPopverState.selectedResourcesTag = cloneDeep(event.detail.selectedValues);
    }

    handleSearchText(event) {
        const value = slwcUtils.getValueFromEvent(event);
        this.clonedFilterPopverState.queryText = value;
        this.sendData()
    }
    sendData() {
        const valuesChangeEvent = new CustomEvent('change', {
            detail: {
                value: this.clonedFilterPopverState,
            }
        });
        this.dispatchEvent(valuesChangeEvent);
    }
}