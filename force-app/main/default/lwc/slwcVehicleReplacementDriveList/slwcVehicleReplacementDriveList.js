import { LightningElement, api, track } from 'lwc';
import { DateTime } from 'c/luxon';

const TAB = { ALL: 'All', SUCCESSFUL: 'Successful', ERROR: 'Error' };

const STATUS_GROUPS_BASE = [
  { status: TAB.ALL, label: TAB.ALL, countClass: 'drives-count' },
  { status: TAB.SUCCESSFUL, label: TAB.SUCCESSFUL, countClass: 'drives-count status__completed' },
  { status: TAB.ERROR, label: TAB.ERROR, countClass: 'drives-count status__error' }
];

const STATUS_BADGE_MAP = {
  'Confirmed': 'slds-badge slds-theme_success',
  'Tentative': 'slds-badge',
  'Cancelled': 'slds-badge slds-theme_error',
  'Complete': 'slds-badge slds-theme_shade'
};

const ERROR_BAND_STYLE = 'background:#fce7e6;border-left:4px solid #c23934;';
const WARNING_BAND_STYLE = 'background:#fffbe6;border-left:4px solid #f8c900;';

export default class SlwcVehicleReplacementDriveList extends LightningElement {
  @api drives = [];
  @api selectedDriveIds;
  @api overriddenDriveIds;
  @api totalMatches = 0;
  @api currentPage = 1;
  @api pageSize = 10;
  @api currentVehicle;
  @api replacementVehicle;
  @api acknowledgedContentionIds;

  @track selectedTab = TAB.ALL;

  get enrichedDrives() {
    const selected = new Set(this.selectedDriveIds || []);
    const overridden = new Set(this.overriddenDriveIds || []);
    const acknowledged = new Set(this.acknowledgedContentionIds || []);
    return (this.drives || []).map(drive => {
      const isSelected = selected.has(drive.id);
      const exceptions = (drive.exceptions || []).map((exc, idx) => {
        const isError = exc.severity === 'error';
        const key = `${drive.id}_exc_${idx}`;
        const overrideKey = `${drive.id}_${idx}`;
        return {
          ...exc,
          key,
          isError,
          isOverridden: overridden.has(overrideKey),
          bandClass: isError ? 'exception-band exception-band_error' : 'exception-band exception-band_warning',
          bandStyle: isError ? ERROR_BAND_STYLE : WARNING_BAND_STYLE
        };
      });
      const contentions = (drive.contentions || []).map((c, idx) => {
        const key = `${drive.id}_con_${idx}`;
        return { ...c, key, isAcknowledged: acknowledged.has(key) };
      });
      const isCheckboxDisabled = contentions.some(c => !c.isAcknowledged);
      return {
        ...drive,
        isSelected,
        exceptions,
        contentions,
        isCheckboxDisabled,
        rowClass: drive.hasException ? 'drive-row drive-row_has-exception' : 'drive-row',
        statusBadgeClass: STATUS_BADGE_MAP[drive.status] || 'slds-badge',
        driveDateDisplay: drive.driveDate ? DateTime.fromISO(drive.driveDate).toFormat('MMM dd, yyyy') : '',
        recordPageUrl: '/' + drive.id,
        driveCapDisplay: `${(this.currentVehicle && this.currentVehicle.presDonorCapacity) || '-'} / ${drive.vehicleCapacity || '-'}`,
        projDonorsDisplay: drive.projectedRegisteredDonors || '-',
        vehCapDisplay: (this.replacementVehicle && this.replacementVehicle.presDonorCapacity) || '-'
      };
    });
  }

  get displayedDrives() {
    const all = this.enrichedDrives;
    if (this.selectedTab === TAB.SUCCESSFUL) return all.filter(d => !d.hasException);
    if (this.selectedTab === TAB.ERROR) return all.filter(d => d.hasException);
    return all;
  }

  get allSelected() {
    const selected = new Set(this.selectedDriveIds || []);
    const selectable = this.displayedDrives.filter(d => !d.isCheckboxDisabled);
    return selectable.length > 0 && selectable.every(d => selected.has(d.id));
  }

  get noDrives() {
    return this.displayedDrives.length === 0;
  }

  get pageLabel() {
    return `Showing ${(this.drives || []).length} of ${this.totalMatches} potential matches`;
  }

  get isPrevDisabled() {
    return this.currentPage <= 1;
  }

  get isNextDisabled() {
    return (this.currentPage * this.pageSize) >= this.totalMatches;
  }

  get statusGroups() {
    const all = this.enrichedDrives;
    const counts = {
      [TAB.ALL]: all.length,
      [TAB.SUCCESSFUL]: all.filter(d => !d.hasException).length,
      [TAB.ERROR]: all.filter(d => d.hasException).length
    };
    const base = this.replacementVehicle ? STATUS_GROUPS_BASE : STATUS_GROUPS_BASE.filter(g => g.status === TAB.ALL);
    return base.map(g => ({
      ...g,
      count: counts[g.status],
      tabClass: `slds-grid slds-grid_vertical-align-center scheduling-status__filter-item${g.status === this.selectedTab ? ' is-selected' : ''}`
    }));
  }

  handleFilterTab(event) {
    this.selectedTab = event.currentTarget.dataset.value;
  }

  handleSelectAll(event) {
    const isChecked = event.target.checked;
    this.displayedDrives.filter(d => !d.isCheckboxDisabled).forEach(drive => {
      this.dispatchEvent(new CustomEvent('rowselection', {
        detail: { driveId: drive.id, isSelected: isChecked }
      }));
    });
  }

  handleRowCheckbox(event) {
    const driveId = event.target.dataset.driveId;
    const isSelected = event.target.checked;
    this.dispatchEvent(new CustomEvent('rowselection', {
      detail: { driveId, isSelected }
    }));
  }

  handleContentionAcknowledge(event) {
    const conKey = event.target.dataset.conKey;
    const isAcknowledged = event.target.checked;
    this.dispatchEvent(new CustomEvent('contentionacknowledge', {
      detail: { conKey, isAcknowledged }
    }));
  }

  handleOverrideChange(event) {
    const overrideKey = event.target.dataset.excKey;
    const isOverridden = event.target.checked;
    this.dispatchEvent(new CustomEvent('override', {
      detail: { overrideKey, isOverridden }
    }));
  }

  handlePrev() {
    this.dispatchEvent(new CustomEvent('paginate', { detail: { direction: 'prev' } }));
  }

  handleNext() {
    this.dispatchEvent(new CustomEvent('paginate', { detail: { direction: 'next' } }));
  }
}