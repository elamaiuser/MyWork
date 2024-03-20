import { LightningElement, track, api } from 'lwc';
import { dataService, queryModelBase } from 'c/dataService';

const MINIMAL_SEARCH_TERM_LENGTH = 2; // Min number of chars required to search
const SEARCH_DELAY = 300; // Wait 300 ms after user stops typing then, peform search

export default class SlwcLookup extends LightningElement {
    @api label;
    @api placeholder = '';
    @api name;
    @api iconName;
    @api objectName;
    @api searchField = 'Name';
    @api displayField = 'name';
    @api isMultiEntry = false;
    @api errors = [];
    @api scrollAfterNItems;
    @api customKey;
    @api isCustomSearch = false;
    @api customSearchFunc = null;
    @api beforeRemoveSiteFunc = null;
    @api isReadonly = false;
    @api isRequired = false;
    @api value = null;
    @track searchTerm = '';
    @track searchResults = [];
    @track hasFocus = false;
    @track loading = false;

    @api reportValidity() {
        this.validate();
        [
            ...this.template.querySelectorAll('input[type=text]')
        ].forEach((inputField) => {
            inputField.reportValidity();
        });
    }

    @api checkValidity() {
        const isValid = !this.errors.length;
        return isValid && [
            ...this.template.querySelectorAll('input[type=text]')
        ].reduce((validSoFar, inputField) => {
            return validSoFar && inputField.checkValidity();
        }, true);
    }

    cleanSearchTerm;
    blurTimeout;
    searchThrottlingTimeout;

    // EXPOSED FUNCTIONS
    @api selection = null;

    @api
    setSearchResults(results) {
        // Reset the spinner
        this.loading = false;
        // Clone results before modifying them to avoid Locker restriction
        this.searchResults = JSON.parse(JSON.stringify(results));
    }

    // INTERNAL FUNCTIONS

    updateSearchTerm(newSearchTerm) {
        this.searchTerm = newSearchTerm;
        this.value = newSearchTerm;
        
        // Compare clean new search term with current one and abort if identical
        const newCleanSearchTerm = newSearchTerm.trim().replace(/\*/g, '').toLowerCase();
        if (this.cleanSearchTerm === newCleanSearchTerm) {
            return;
        }

        // Save clean search term
        this.cleanSearchTerm = newCleanSearchTerm;

        // Ignore search terms that are too small
        if (newCleanSearchTerm.length < MINIMAL_SEARCH_TERM_LENGTH) {
            this.searchResults = [];
            return;
        }

        // Apply search throttling (prevents search if user is still typing)
        if (this.searchThrottlingTimeout) {
            clearTimeout(this.searchThrottlingTimeout);
        }
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.searchThrottlingTimeout = setTimeout(() => {
            // Send search event if search term is long enougth
            if (this.cleanSearchTerm.length >= MINIMAL_SEARCH_TERM_LENGTH) {
                // Display spinner until results are returned
                this.loading = true;

                const searchData = {
                    searchTerm: this.cleanSearchTerm,
                    objectName: this.objectName,
                    searchField: this.searchField,
                    selectedIds: []
                };

                let searchFuncCallback = null;
                if (this.isCustomSearch && this.customSearchFunc) {
                    searchFuncCallback = this.customSearchFunc(searchData);
                } 
                else {
                    let objectSearchField = this.searchField ? this.searchField : 'Name';
                    let query = new queryModelBase();
                    query.queryText = this.searchTerm;
                    query.searchColumns = [objectSearchField];

                    let service = new dataService(this.objectName);
                    searchFuncCallback = service.query(query);
                }
                if (searchFuncCallback) {
                    searchFuncCallback.then((data) => {
                        if (this.displayField) {
                            this.searchResults = [];
                            data.forEach(item => {
                                item['label'] = item[this.displayField];

                                let index = -1;
                                if (this.selection && this.selection.length > 0) {
                                    index = this.selection.findIndex(selectedItem => selectedItem.id == item.id);
                                }
                                if (index == -1) {
                                    this.searchResults.push(item);
                                }
                            });
                        }
                        this.loading = false;
                    })
                    .catch((error) => {
                        console.error('Lookup error', JSON.stringify(error));
                        this.errors = [error];
                    });
                }
            }
            this.searchThrottlingTimeout = null;
        }, SEARCH_DELAY);
    }

    isSelectionAllowed() {
        if (this.isMultiEntry) {
            return true;
        }
        return !this.hasSelection();
    }

    hasResults() {
        return this.searchResults.length > 0;
    }

    hasSelection() {
        return this.selection != null && this.selection != undefined;
    }

    validate() {
      this.errors = [];

      if(this.isRequired) {
        if(!this.hasSelection()) {
          this.errors.push({
            id: 'required',
            message: 'Complete this field.'
          });
          return false;
        }
      }

      return true;
    }

    // EVENT HANDLING

    handleInput(event) {
        // Prevent action if selection is not allowed
        if (!this.isSelectionAllowed()) {
            return;
        }
        this.updateSearchTerm(event.target.value);
    }

    handleResultClick(event) {
        const recordId = event.currentTarget.dataset.recordid;

        // Save selection
        let selectedItem = this.searchResults.filter((result) => result.id === recordId);
        if (selectedItem.length === 0) {
            return;
        }
        this.selection = selectedItem[0];

        // Reset search
        this.searchTerm = '';
        this.searchResults = [];

        this.validate();
        // Notify parent components that selection has changed
        const selectionChangeEvent = new CustomEvent('selectionchange', {
            detail: {
                selection: this.selection
            }
        });
        this.dispatchEvent(selectionChangeEvent);
    }

    handleComboboxClick() {
        // Hide combobox immediatly
        if (this.blurTimeout) {
            window.clearTimeout(this.blurTimeout);
        }
        this.hasFocus = false;
    }

    handleFocus() {
        // Prevent action if selection is not allowed
        if (!this.isSelectionAllowed()) {
            return;
        }
        this.hasFocus = true;
    }

    handleBlur() {
        // Prevent action if selection is not allowed
        if (!this.isSelectionAllowed()) {
            return;
        }
        // Delay hiding combobox so that we can capture selected result
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.blurTimeout = window.setTimeout(() => {
            this.hasFocus = false;
            this.blurTimeout = null;
        }, 300);
    }

    handleClearSelection() {
        const remove = () => {
            this.selection = null;
            this.searchTerm = null;
            this.value = null;
            
            this.validate();
            // Notify parent components that selection has changed
            const selectionChangeEvent = new CustomEvent('selectionchange', {
                detail: {
                    selection: this.selection
                }
            });
            this.dispatchEvent(selectionChangeEvent);
        }

        if(!this.beforeRemoveSiteFunc) {
            remove();
            return;
        }

        this.beforeRemoveSiteFunc()
        .then((confirmToRemove) => {
            if(confirmToRemove) {
                remove();
            }
        })  
    }

    // STYLE EXPRESSIONS

    get getContainerClass() {
        let css = 'slds-combobox_container slds-has-inline-listbox ';
        if (this.hasFocus && this.hasResults()) {
            css += 'slds-has-input-focus ';
        }
        if (this.errors.length > 0) {
            css += 'has-custom-error';
        }
        return css;
    }

    get getDropdownClass() {
        let css = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click ';
        if (this.hasFocus && this.cleanSearchTerm && this.cleanSearchTerm.length >= MINIMAL_SEARCH_TERM_LENGTH) {
            css += 'slds-is-open';
        }
        return css;
    }

    get getInputClass() {
        let css = 'slds-input slds-combobox__input has-custom-height ' + (this.errors.length === 0 ? '' : 'has-custom-error ');
        css += 'slds-combobox__input-value ' + (this.hasSelection() ? 'has-custom-border' : '');
        return css;
    }

    get getComboboxClass() {
        let css = 'slds-combobox__form-element slds-input-has-icon ';
        css += this.hasSelection() ? 'slds-input-has-icon_left-right' : 'slds-input-has-icon_right';
        return css;
    }

    get getSearchIconClass() {
        let css = 'slds-input__icon slds-input__icon_right ';
        css += this.hasSelection() ? 'slds-hide' : '';
        return css;
    }

    get getClearSelectionButtonClass() {
        return (
            'slds-button slds-button_icon slds-input__icon slds-input__icon_right ' +
            (this.hasSelection() ? '' : 'slds-hide')
        );
    }

    get getSelectIconClass() {
        return 'slds-combobox__input-entity-icon ' + (this.hasSelection() ? '' : 'slds-hide');
    }

    get getInputValue() {
        const res = this.hasSelection() ? (this.displayField ? this.selection[this.displayField] : this.selection.label) : this.searchTerm
        return res || this.value ;
    }

    get getInputTitle() {
        return this.hasSelection() ? (this.displayField ? this.selection[this.displayField] : this.selection.label) : '';
    }

    get getListboxClass() {
        return (
            'slds-listbox slds-listbox_vertical slds-dropdown slds-dropdown_fluid ' +
            (this.scrollAfterNItems ? 'slds-dropdown_length-with-icon-' + this.scrollAfterNItems : '')
        );
    }

    get isInputReadonly() {
        return this.hasSelection() || this.isReadonly;
    }

    get isExpanded() {
        return this.hasResults();
    }
}