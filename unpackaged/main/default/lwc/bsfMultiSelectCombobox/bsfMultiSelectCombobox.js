import { api, LightningElement, track } from 'lwc';
export default class BsfMultiSelectCombobox extends LightningElement {
  @api disabled = false;
  @api label = '';
  @api name;
  @api options = [];
  @api placeholder = 'Select an Option';
  @api readOnly = false;
  @api required = false;
  @api singleSelect = false;
  @api showPills = false;
  @api showOptions = false;
  @api resetSelection = false;
  @api selectedItems = [];

  @api overritecurrent(){
    this.currentOptions = [];
  }

  @track currentOptions = [];
  
  selectedOptions = [];
  isInitialized = false;
  isLoaded = false;
  isVisible = false;
  isDisabled = false;

  connectedCallback() {
    this.isDisabled = this.disabled || this.readOnly;
    this.hasPillsEnabled = this.showPills && !this.singleSelect;
    this.currentOptions = this.options;
    this.showOptions = true;
  }

  renderedCallback() {
    if (!this.isInitialized) {
      this.template.querySelector('.multi-select-combobox__input').addEventListener('click', (event) => {
        this.handleClick(event.target);
        event.stopPropagation();
      });
      this.template.addEventListener('click', (event) => {
        event.stopPropagation();
      });
      document.addEventListener('click', () => {
        this.close();
      });
      this.isInitialized = true;
      this.showOptions = true;
      this.setSelection();
    }
  }

  handleChange(event) {
    this.change(event);
  }

  handleRemove(event) {
    this.selectedOptions.splice(event.detail.index, 1);
    this.change(event);
  }

  handleClick() {
    this.showOptions = true;
    if (this.isLoaded === false || this.currentOptions?.length !== this.options?.length) {
      this.currentOptions = JSON.parse(JSON.stringify(this.options));
      this.isLoaded = true;
    }

    if (this.template.querySelector('.slds-is-open')) {
      this.close();
    } else {
      this.template.querySelectorAll('.multi-select-combobox__dropdown').forEach((node) => {
        node.classList.add('slds-is-open');
      });
    }
    this.dispatchEvent(new CustomEvent('clickevent', { detail: {click: true}}));
  }

  change(event) {
    if (this.singleSelect) {
      this.currentOptions.forEach((item) => (item.selected = false));
    }

    this.currentOptions
      .filter((item) => item.value === event.detail.item.value)
      .forEach((item) => (item.selected = event.detail.selected));
    this.setSelection();
    const selection = this.getSelectedItems();
    this.dispatchEvent(new CustomEvent('change', { detail: this.singleSelect ? selection[0] : selection }));

    if (this.singleSelect) {
      this.close();
    }
  }

  close() {
    this.template.querySelectorAll('.multi-select-combobox__dropdown').forEach((node) => {
      node.classList.remove('slds-is-open');
    });
    this.dispatchEvent(new CustomEvent('close'));
  }

  setSelection() {
    const selectedItems = this.getSelectedItems();
    let selection = '';
    if (selectedItems.length < 1) {
      selection = this.placeholder;
      this.selectedOptions = [];
    } else if (selectedItems.length > 2) {
      selection = `${selectedItems.length} Options Selected`;

      this.selectedOptions = this.getSelectedItems();
    } else {
      selection = selectedItems.map((selected) => selected.label).join(', ');
      this.selectedOptions = this.getSelectedItems();
    }
    this.selectedItems = selection;
    this.isVisible = this.selectedOptions && this.selectedOptions.length > 0;
  }

  getSelectedItems() {
    var cOptions = [];
    if(this.currentOptions) {
      cOptions = this.currentOptions.filter((item) => item.selected);
    }
    return cOptions;
  }
}