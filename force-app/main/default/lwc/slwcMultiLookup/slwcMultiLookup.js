import { LightningElement, track, api } from 'lwc';
import { dataService, queryModelBase } from 'c/dataService';
import { isBoolean, remove } from 'c/lodash';
const MINIMAL_SEARCH_TERM_LENGTH = 1; // Min number of chars required to search
const SEARCH_DELAY = 400; // Wait 300 ms after user stops typing then, peform search

export default class SlwcMultiLookup extends LightningElement {
    @api label;
    @api name;
    @api placeholder = '';
    @api iconName;
    @api objectName;
    @api searchField = 'Name';
    @api displayField = 'name';
    @api displaySublineField;
    @api errors = [];
    @api scrollAfterNItems;
    @api customKey;
    @api isCustomSearch = false;
    @api customSearchFunc = null;

    @track searchTerm = '';
    @track searchResults = [];
    @track showOptions = false;
    @track loading = false;

    cleanSearchTerm;
    searchThrottlingTimeout;

    // EXPOSED FUNCTIONS
    @api selection = [];

    @api
    getkey() {
        return this.customKey;
    }

    // INTERNAL FUNCTIONS

    updateSearchTerm(newSearchTerm) {
        this.searchTerm = newSearchTerm;

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
    }

    handleSearch() {
         // Apply search throttling (prevents search if user is still typing)
         if (this.searchThrottlingTimeout) {
            clearTimeout(this.searchThrottlingTimeout);
        }
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.searchThrottlingTimeout = setTimeout(() => {
            // Send search event if search term is long enougth
            if (this.cleanSearchTerm != null && this.cleanSearchTerm != undefined && this.cleanSearchTerm.length >= MINIMAL_SEARCH_TERM_LENGTH) {
                // Display spinner until results are returned
                this.loading = true;

                const searchData = {
                    searchTerm: this.cleanSearchTerm,
                    objectName: this.objectName,
                    searchField: this.searchField,
                    selectedIds: this.selection.map((element) => element.id)
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
                                if (this.displaySublineField) {
                                    item['subline'] = item[this.displaySublineField];
                                }

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

    hasResults() {
        return this.searchResults.length > 0;
    }

    hasSelection() {
        return this.selection.length > 0;
    }

    // EVENT HANDLING

    handleInput(event) {
        this.updateSearchTerm(event.target.value);
        this.handleSearch();
    }

    handleResultClick(event) {
        const recordId = event.currentTarget.dataset.recordid;

        // Save selection
        let selectedItem = this.searchResults.filter((result) => result.id === recordId);
        if (selectedItem.length === 0) {
            return;
        }
        selectedItem = selectedItem[0];
        const newSelection = [...this.selection];
        newSelection.push(selectedItem);
        this.selection = newSelection;

        window.setTimeout(() => {
            remove(this.searchResults, item => item.id === recordId);
        })

        // Notify parent components that selection has changed
        const selectionChangeEvent = new CustomEvent('selectionchange', {
            detail: {
                selection: this.selection
            }
        });
        this.dispatchEvent(selectionChangeEvent);
    }

    closeDropdown = () => {
        this.toggleOptions(false);
    }

    toggleOptions(force) {
        setTimeout(() => {
            this.showOptions = isBoolean(force) ? force : !this.showOptions;

            if(this.showOptions) {
                this.handleSearch();
            }
        })
    }

    handleRemoveSelectedItem(event) {
        const recordId = event.currentTarget.name;
        this.selection = this.selection.filter((item) => item.id !== recordId);
        // Notify parent components that selection has changed
        const selectionChangeEvent = new CustomEvent('selectionchange', {
            detail: {
                selection: this.selection
            }
        });
        this.dispatchEvent(selectionChangeEvent);
    }

    handleClearSelection() {
        this.selection = [];
        // Notify parent components that selection has changed
        const selectionChangeEvent = new CustomEvent('selectionchange', {
            detail: {
                selection: this.selection
            }
        });
        this.dispatchEvent(selectionChangeEvent);
    }

    // STYLE EXPRESSIONS
    get getInputClass() {
        let css = 'slds-input slds-combobox__input has-custom-height ' + (this.errors.length === 0 ? '' : 'has-custom-error ');
        return css;
    }

    get showNoResultsText() {
        return !this.hasResults();
    }
}