import { api, track } from 'lwc';
import LightningModal from 'lightning/modal';
import { DateTime } from 'c/luxon';

export default class SlwcVehiclePickerModal extends LightningModal {
  @api vehicles = [];
  @api hideExceptions = false;
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
        relocatedKey: `${v.id}_relocated`,
        showRelocated: !this.hideExceptions && v.isRelocated,
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

  handleVehicleSelect(event) {
    this.currentSelectedId = event.target.dataset.id;
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