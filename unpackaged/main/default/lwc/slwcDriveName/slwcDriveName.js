import { LightningElement, api } from 'lwc';
import * as slwcUtils from 'c/slwcUtils';

export default class SlwcDriveName extends LightningElement {
  @api drive;
  @api hideDriveIndicator = false;
  
  get driveUrl() {
    if(!this.drive) return null;
    return '/' + this.drive.id;
  }

  get indicatorClass() {
    if(!this.drive) return null;

    const totalStaffRequested = this.drive.totalStaffRequested || 0;
    const staffAllocated = this.drive.staffAllocated || 0;

    return slwcUtils.classNames('indicator', {
      'Staffed': totalStaffRequested === staffAllocated,
      'Overstaffed': totalStaffRequested < staffAllocated,
      'Understaffed': totalStaffRequested > staffAllocated
    });
  } 
}