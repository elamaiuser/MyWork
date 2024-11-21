import { LightningElement, wire, track, api } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { DriveHelper } from 'c/slwcDriveGenerator';
import * as slwcUtils from 'c/slwcUtils';

export default class SlwcDriveCompactView extends LightningElement {
    driveHelper = new DriveHelper();

    @track drive;
    @track masterData;

    @wire(CurrentPageReference) pageRef;

    @api 
    set driveDetails(input) {
        this.drive = input;
    }
    get driveDetails() {
        return this.drive;
    }

    @api
    set masterDataDetails(input) {
        this.masterData = input;
    }
    get masterDataDetails() {
        return this.masterData;
    }

    get isFixedSiteDrive() {
        return this.driveHelper.isFixedSiteDrive(this.drive);
    }

    get showPlateletField() {
        return this.driveHelper.showPlateletField(this.drive);
    }

    get showPlasmaField() {
        return this.driveHelper.showPlasmaField(this.drive);
    }

    get showWBField() {
        return this.driveHelper.showWBField(this.drive);
    }

    get x2rbcEnabled() {
        return this.driveHelper.x2rbcEnabled(this.drive);
    }

    get show2RBCField() {
        return this.driveHelper.show2RBCField(this.drive);
    }

    get driveStaffCapacity() {
        if(!this.drive || !this.drive.staffCapacity) return 0;
        return Math.ceil(Number(this.drive.staffCapacity));
    }
    
    // handle lightning-input changed
    handleOnChange(event) {
        let targetName = event.target.name;
        let targetValue = slwcUtils.getValueFromEvent(event);

        clearTimeout(this.timeoutId); // no-op if invalid id
        this.timeoutId = setTimeout(() => {
            this.dispatchEvent(
                new CustomEvent('drivedatachanged', {
                    bubbles: true,
                    composed: true,
                    detail: {
                        cmpName: 'slwcDriveCompactView',
                        properties: [
                            {
                                targetName: targetName,
                                targetValue: targetValue
                            }
                        ]
                    }
                })
            );
        }, 800);
    }
    
}