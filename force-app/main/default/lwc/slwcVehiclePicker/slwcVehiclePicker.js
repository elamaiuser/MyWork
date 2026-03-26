import { LightningElement, api, track } from 'lwc';
import SlwcVehiclePickerModal from 'c/slwcVehiclePickerModal';

export default class SlwcVehiclePicker extends LightningElement {
  @api label = '';
  @api iconName = 'utility:transport_heavy_truck';
  @api vehicles = [];
  @api excludeVehicleId = null;
  @api disabled = false;
  @api hideExceptions = false;

  @track selectedVehicle = null;
  @track searchTerm = '';
  @track isDropdownOpen = false;

  get availableVehicles() {
    return (this.vehicles || []).filter(v => v.id !== this.excludeVehicleId);
  }

  get filteredVehicles() {
    const term = this.searchTerm.toLowerCase();
    return this.availableVehicles.filter(v => v.name.toLowerCase().includes(term));
  }

  get inputValue() {
    return this.selectedVehicle ? this.selectedVehicle.name : this.searchTerm;
  }

  get isInputReadonly() {
    return !!this.selectedVehicle;
  }

  get comboboxClass() {
    return `slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click${this.isDropdownOpen ? ' slds-is-open' : ''}`;
  }

  handleSearchInput(event) {
    this.searchTerm = event.target.value;
    this.isDropdownOpen = true;
  }

  handleSearchFocus() {
    this.isDropdownOpen = true;
  }

  handleSearchBlur() {
    setTimeout(() => { this.isDropdownOpen = false; }, 200);
  }

  handleSelectFromDropdown(event) {
    const vehicleId = event.currentTarget.dataset.id;
    const vehicle = this.availableVehicles.find(v => v.id === vehicleId);
    if (vehicle) {
      this._selectVehicle(vehicle);
    }
  }

  @api
  clearSelection() {
    this.selectedVehicle = null;
    this.searchTerm = '';
    this.isDropdownOpen = false;
  }

  handleClear() {
    this.clearSelection();
    this.dispatchEvent(new CustomEvent('vehiclecleared'));
  }

  handleOpenModal() {
    SlwcVehiclePickerModal.open({
      size: 'medium',
      vehicles: this.availableVehicles,
      hideExceptions: this.hideExceptions,
      selectedVehicleId: this.selectedVehicle ? this.selectedVehicle.id : null
    }).then(result => {
      if (result) {
        this._selectVehicle(result);
      }
    });
  }

  _selectVehicle(vehicle) {
    this.selectedVehicle = vehicle;
    this.searchTerm = '';
    this.isDropdownOpen = false;
    this.dispatchEvent(new CustomEvent('vehicleselected', { detail: { vehicle } }));
  }
}