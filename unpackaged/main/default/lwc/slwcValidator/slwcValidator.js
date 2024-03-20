import { DRIVE_TYPE } from "c/slwcConstants";
import { isNullOrEmpty } from "c/slwcUtils";
import { DriveHelper } from 'c/slwcDriveGenerator';
import { DateTime } from 'c/luxon';

const VALIDATION_TYPES = {
    REQUIRED: {},
    CUSTOM: {},
    PAST_DATE: {}
}

class validatorBase {
    constructor() {
        this.options = [];
        this.result = [];
        this.todayVal = new Date(new Date().setHours(0,0,0,0));
    }

    validate(obj) {
        obj.validities = [];
        for (var property in obj) {
            let options = this.options.filter((result) => result.property === property);
            for (let i = 0; i < options.length; i++) {
                let message = this.getMessage(obj, property, options[i]);
                if (message !== '') {
                    obj.validities.push({
                        field: options[i].property,
                        message: message
                    });
                }
            }
        }
    }

    getMessage(obj, property, option) {
        let isValid = true;
        switch (option.type) {
            case VALIDATION_TYPES.REQUIRED:
                if (obj[property] == undefined || obj[property] == null) {
                    isValid = false;
                }
                break;
                
            case VALIDATION_TYPES.CUSTOM:
                if (option.checkValid(obj) != true) {
                    isValid = false;
                }
                break;
            
            case VALIDATION_TYPES.PAST_DATE:
                if (obj[property]) {
                    let dt = new Date(obj[property]).setHours(0,0,0,0);
                    if (dt < this.todayVal) {
                        isValid = false;
                    }
                }
                break;

            default:
                break;
        }
        return isValid ? '' : (option.message ? option.message : option.type.message);
    }
}

class clientAvailabilityValidator extends validatorBase {
    validationRules = [
        {
            property: 'start',
            type: VALIDATION_TYPES.REQUIRED,
            message: 'Start is required.'
        },
        {
            property: 'finish',
            type: VALIDATION_TYPES.REQUIRED,
            message: 'End is required.'
        },
        {
            property: 'start',
            type: VALIDATION_TYPES.CUSTOM,
            message: 'Start must be before End.',
            checkValid(obj) {
                let result = true;
                if (obj.start && obj.finish) {
                    result = obj.start < obj.finish;
                }
                return result; 
            }
        },
        {
            property: 'preferredStart',
            type: VALIDATION_TYPES.CUSTOM,
            message: 'Preferred Start is required.',
            checkValid(obj) {
                if (obj.isCustomTimePreferred == true) {
                    return obj.preferredStart != null && obj.preferredStart != undefined;
                }
                return true;
            }
        },
        {
            property: 'preferredEnd',
            type: VALIDATION_TYPES.CUSTOM,
            message: 'Preferred End is required.',
            checkValid(obj) {
                if (obj.isCustomTimePreferred == true) {
                    return obj.preferredEnd != null && obj.preferredEnd != undefined;
                }
                return true;
            }
        },
        {
            property: 'preferredStart',
            type: VALIDATION_TYPES.CUSTOM,
            message: 'Preferred Start must be before Preferred End.',
            checkValid(obj) {
                let result = true;
                if (obj.isCustomTimePreferred == true) {
                    if (obj.preferredStart && obj.preferredEnd) {
                        result = obj.preferredStart <= obj.preferredEnd;
                    }
                }
                return result; 
            }
        }
    ];

    constructor() {
        super();
        this.options.push(...this.validationRules);
    }
}

class driveValidator extends validatorBase {
    timezoneSidId;

    validationRules = [
        {
            property: 'driveDate',
            type: VALIDATION_TYPES.REQUIRED,
            message: 'Drive Date is required.'
        },
        {
            property: 'startTime',
            type: VALIDATION_TYPES.REQUIRED,
            message: 'Drive Start Time is required.'
        },
        {
            property: 'endTime',
            type: VALIDATION_TYPES.REQUIRED,
            message: 'Drive End Time is required.'
        },
        {
            property: 'driveDate',
            type: VALIDATION_TYPES.CUSTOM,
            message: 'Drive Date is invalid.',
            checkValid(obj) {
                let today =  DateTime.fromObject({
                    zone: this.timezoneSidId
                }).toISODate();
                return obj["driveDate"] >= today;
            }
        },
        {
            property: 'projectedRegisteredDonors',
            type: VALIDATION_TYPES.CUSTOM,
            message: 'Projected Registered Donors is required.',
            checkValid(obj) {
                const helper = new DriveHelper();
                if (helper.isFixedSiteDrive(obj)) {
                    return true;
                }

                return !isNullOrEmpty(obj.projectedRegisteredDonors);
            }
        },
        {
            property: 'name',
            type: VALIDATION_TYPES.REQUIRED,
            message: 'Drive Name is required.'
        },
        {
            property: 'startTime',
            type: VALIDATION_TYPES.CUSTOM,
            message: 'Start Time must be before End Time.',
            checkValid(obj) {
                let result = true;
                if (obj.startTime && obj.endTime) {
                    result = obj.startTime <= obj.endTime;
                }
                return result; 
            }
        }
    ];

    constructor({
        timezoneSidId
    }) {
        super();
        this.timezoneSidId = timezoneSidId;
        this.options.push(...this.validationRules);
    }

    validate(drive) {
        super.validate(drive);
        
        if (drive.driveShifts && drive.driveShifts.length > 0) {
            let driveShiftValidatorIns = new driveShiftValidator();
            let totalDonorsScheduled = 0;
            drive.driveShifts.forEach((driveShift) => {
                if (driveShift.donorsScheduled) {
                    totalDonorsScheduled += driveShift.donorsScheduled;
                }
                driveShiftValidatorIns.validate(driveShift);

                if (driveShift.startTime) {
                    if (driveShift.startTime < drive.startTime || driveShift.startTime > drive.endTime) {
                        driveShift.validities.push({
                            field: "startTime",
                            message: "Start Time must be during Draw Hours."
                        });
                    }
                }
                if (driveShift.endTime) {
                    if (driveShift.endTime < drive.startTime || driveShift.endTime > drive.endTime) {
                        driveShift.validities.push({
                            field: "endTime",
                            message: "End Time must be during Draw Hours."
                        });
                    }
                }

                if (!driveShift.lunchBreakBeforeDrawHours) {
                    if (driveShift.lunchBreak) {
                        if (driveShift.lunchBreakStartTime) {
                            if (driveShift.lunchBreakStartTime < drive.startTime || driveShift.lunchBreakStartTime > drive.endTime) {
                                driveShift.validities.push({
                                    field: "lunchBreakStartTime",
                                    message: "Lunch Break Start Time must be during Draw Hours."
                                });
                            }
                        }
                        if (driveShift.lunchBreakEndTime) {
                            if (driveShift.lunchBreakEndTime < drive.startTime || driveShift.lunchBreakEndTime > drive.endTime) {
                                driveShift.validities.push({
                                    field: "lunchBreakEndTime",
                                    message: "Lunch Break End Time must be during Draw Hours."
                                });
                            }
                        }
                    }
                }
            });

            if(drive.typeOfDrive === DRIVE_TYPE.MOBILE) {
                if (drive.projectedRegisteredDonors != null && drive.projectedRegisteredDonors != undefined) {
                    if (drive.projectedRegisteredDonors != totalDonorsScheduled) {
                        drive.validities.push({
                            field: "projectedRegisteredDonors",
                            message: "Projected Registered Donors must be equal to total Projected Registered Donors."
                        });
                    }
                }
            }
        }
    }
}

class driveShiftValidator extends validatorBase {
    validationRules = [
        {
            property: 'donorsSchedule',
            type: VALIDATION_TYPES.REQUIRED,
            message: 'Projected Registered Donors is required.'
        },
        {
            property: 'start',
            type: VALIDATION_TYPES.REQUIRED,
            message: 'Start is required.'
        },
        {
            property: 'finish',
            type: VALIDATION_TYPES.REQUIRED,
            message: 'Finish is required.'
        },
        {
            property: 'vehiclesNeeded',
            type: VALIDATION_TYPES.REQUIRED,
            message: 'Vehicle is required.'
        },
        {
            property: 'start',
            type: VALIDATION_TYPES.CUSTOM,
            message: 'Start must be before Finish.',
            checkValid(obj) {
                let result = true;
                if (obj.start && obj.finish) {
                    result = obj.start <= obj.finish;
                }
                return result; 
            }
        },
        {
            property: 'lunchBreakStartTime',
            type: VALIDATION_TYPES.CUSTOM,
            message: 'Lunch Break Start Time must be before Lunch Break End Time.',
            checkValid(obj) {
                let result = true;
                if (obj.lunchBreak == true) {
                    if (obj.lunchBreakStartTime && obj.lunchBreakEndTime) {
                        result = obj.lunchBreakStartTime <= obj.lunchBreakEndTime;
                    }
                }
                return result; 
            }
        }
    ];

    constructor() {
        super();
        this.options.push(...this.validationRules);
    }
}

class locationAvailabilityValidator extends validatorBase {
    validationRules = [
        {
            property: 'start',
            type: VALIDATION_TYPES.REQUIRED,
            message: 'Start is required.'
        },
        {
            property: 'finish',
            type: VALIDATION_TYPES.REQUIRED,
            message: 'End is required.'
        },
        {
            property: 'start',
            type: VALIDATION_TYPES.CUSTOM,
            message: 'Start must be before End.',
            checkValid(obj) {
                let result = true;
                if (obj.start && obj.finish) {
                    result = obj.start <= obj.finish;
                }
                return result; 
            }
        }
    ];

    constructor() {
        super();
        this.options.push(...this.validationRules);
    }
}

export {
    clientAvailabilityValidator,
    driveValidator,
    driveShiftValidator,
    locationAvailabilityValidator
}