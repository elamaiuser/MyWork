import { LightningElement, api, track } from 'lwc';
import { DriveHelper } from 'c/slwcDriveGenerator';

export default class SlwcFixedSiteTab extends LightningElement {
  driveHelper = new DriveHelper();
  @api drive = null;
  @api masterData = null;

  get drivePlateletRounds() {
    return this.driveHelper.getDrivePlateletRounds(drive);
  }
}