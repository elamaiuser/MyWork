import { api } from 'lwc';
import LightningModal from 'lightning/modal';
import { DateTime } from 'c/luxon';

export default class SlwcVehicleReplacementConfirmModal extends LightningModal {
  @api currentVehicle;
  @api replacementVehicle;
  @api drives = [];

  get enrichedDrives() {
    return (this.drives || []).map(drive => ({
      ...drive,
      driveDateDisplay: drive.driveDate ? DateTime.fromISO(drive.driveDate).toFormat('MMM dd, yyyy') : '',
      contentionMessages: (drive.contentions || [])
        .filter(c => c.message)
        .map((c, idx) => ({ key: `${drive.id}_con_${idx}`, message: c.message })),
      hasContentions: (drive.contentions || []).some(c => c.message)
    }));
  }

  get driveCount() {
    return (this.drives || []).length;
  }

  handleConfirm() {
    this.close('confirm');
  }

  handleCancel() {
    this.close();
  }
}