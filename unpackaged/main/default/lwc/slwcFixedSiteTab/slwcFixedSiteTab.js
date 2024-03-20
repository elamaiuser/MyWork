import { LightningElement, api, track } from 'lwc';

export default class SlwcFixedSiteTab extends LightningElement {
  @api drive = null;
  @api masterData = null;

  get drivePlateletRounds() {
    if(!this.drive || !this.drive.driveShiftsMetadata) return null;

    return (this.drive.driveShiftsMetadata.driveShifts || []).reduce((result, item) => {
      return result + (item.numberOfRounds || 0)
    }, 0);
  }
}