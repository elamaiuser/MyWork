import { api, track } from 'lwc';
import LightningModal from 'lightning/modal';
import { DateTime } from 'c/luxon';

export default class SlwcVehiclePickerModal extends LightningModal {
  @api vehicles = [];
  @api selectedVehicleId = null;

  @track searchTerm = '';
  @track currentSelectedId = null;

  connectedCallback() {
    this.currentSelectedId = this.selectedVehicleId;
  }

  get filteredVehicles() {
    const term = this.searchTerm.toLowerCase();
    return (this.vehicles || [])
      .filter(v => v.name.toLowerCase().includes(term))
      .map(v => ({
        ...v,
        isSelected: v.id === this.currentSelectedId,
        rowClass: v.id === this.currentSelectedId ? 'slds-is-selected' : '',
        hasBadge: v.isRelocated || v.DOT || v.CDL,
        effectiveDateDisplay: v.effectiveDate ? DateTime.fromISO(v.effectiveDate).toFormat('MMM dd, yyyy') : '',
        futureInactiveDateDisplay: v.futureInactiveDate ? DateTime.fromISO(v.futureInactiveDate).toFormat('MMM dd, yyyy') : ''
      }));
  }

  get isSaveDisabled() {
    return !this.currentSelectedId;
  }

  get noResults() {
    return this.filteredVehicles.length === 0;
  }

  handleSearch(event) {
    this.searchTerm = event.target.value;
  }

  handleLinkClick(event) {
    event.stopPropagation();
    const vehicleId = event.currentTarget.dataset.id;
    window.open(`/${vehicleId}`, '_blank');
  }

  handleVehicleSelect(event) {
    this.currentSelectedId = event.currentTarget.dataset.id;
  }

  handleVehicleDoubleClick(event) {
    const vehicleId = event.currentTarget.dataset.id;
    const vehicle = (this.vehicles || []).find(v => v.id === vehicleId);
    if (vehicle) {
      this.close(vehicle);
    }
  }

  handleSave() {
    const vehicle = (this.vehicles || []).find(v => v.id === this.currentSelectedId);
    if (vehicle) {
      this.close(vehicle);
    }
  }

  handleCancel() {
    this.close();
  }
}