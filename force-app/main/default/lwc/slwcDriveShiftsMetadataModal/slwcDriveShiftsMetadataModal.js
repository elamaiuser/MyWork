import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { getValueFromEvent } from 'c/slwcUtils';
import { cloneDeep, take, uniqueId, sumBy } from 'c/lodash';
import { DateTime } from 'c/luxon';
import { OPERATION_TYPE, PROCEDURE_TYPE } from 'c/slwcConstants';
import { DriveHelper } from 'c/slwcDriveGenerator';

export default class SlwcDriveShiftsMetadataModal extends LightningElement {
  driveHelper = new DriveHelper();

  @api masterData;
  @api drive;
  @track _isOpen = false;
  @api
  get isOpen() {
    return this._isOpen;
  }
  set isOpen(value) {
    this._isOpen = value;
    if (this._isOpen) {
      this.init();
    }
  }

  @track model = {};
  @track numberOfShiftsOptions = [];
  @track errorMessages = [];

  get isFixedSiteDrive() {
    return this.driveHelper.isFixedSiteDrive(this.drive);
  }

  get canGenerateRounds() {
    return this.isFixedSiteDrive && ![OPERATION_TYPE.NON_INTEGRATED_WB].includes(this.drive.operationType);
  }

  get showProjectedRegisterdDonors() {
    return !this.isFixedSiteDrive;
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

  @wire(CurrentPageReference) pageRef;

  connectedCallback() {
  }

  disconnectedCallback() {
  }

  /** Custom functions **/
  closeModal() {
    this.dispatchEvent(new CustomEvent('close', {
      detail: {

      }
    }));
  }

  init() {
    this.errorMessages = [];
    this.model = cloneDeep(this.drive.driveShiftsMetadata);
    this.generateNumberOfShiftsOptions();

    this.model.driveShifts.forEach(driveShift => {
      this.generateNumberOfRoundsOptions(driveShift);
    })
  }

  generateDriveShiftRounds(driveShift, numberOfRounds = 1) {
    if (!this.canGenerateRounds) return [];
    if (!driveShift) return [];

    let rounds = [];
    let driveShiftIndex = this.model.driveShifts.findIndex(item => item.key === driveShift.key);
    let previousDriveShift = this.model.driveShifts[driveShiftIndex - 1];
    let shiftStart = this.newDateTime(this.drive.driveDate, driveShift.startTime, this.masterData.timezoneSidId);
    if(previousDriveShift) {
      const lastPreviousDriveShiftRound = previousDriveShift.rounds[previousDriveShift.rounds.length - 1];
      if(lastPreviousDriveShiftRound && lastPreviousDriveShiftRound.end > shiftStart) {
        shiftStart = lastPreviousDriveShiftRound.end;
      }
    }

    let shiftEnd = this.newDateTime(this.drive.driveDate, driveShift.endTime, this.masterData.timezoneSidId);
    for (let i = 0; i < numberOfRounds; i++) {
      let roundStart = new Date(shiftStart.getTime() + (i * 3 * 60 * 60000));
      let roundEnd = new Date(roundStart.getTime() + (3 * 60 * 60000)); //3hrs duration
      if (roundStart.getTime() < shiftEnd.getTime()) {
        rounds.push({
          key: uniqueId('round_'),
          label: `Round ${i + 1}`,
          start: roundStart,
          end: roundEnd,
          startTime: this.dateJSToTimeIso(roundStart),
          endTime: this.dateJSToTimeIso(roundEnd)
        })
      }
    }

    return rounds;
  }

  generateDriveShifts() {
    const driveHelper = new DriveHelper();

    this.model.driveShifts = [];
    
    let driveStart = this.newDateTime(this.drive.driveDate, this.drive.startTime, this.masterData.timezoneSidId);
    let driveEnd = this.newDateTime(this.drive.driveDate, this.drive.endTime, this.masterData.timezoneSidId);
    let driveDuration = (driveEnd.getTime() - driveStart.getTime()) / 60000; //minutes
    let totalRounds = 0;
    let roundDuration = 0;
    if(this.canGenerateRounds) {
      roundDuration = 3 * 60;
      totalRounds = driveHelper.calculatePlateletRounds(this.drive, this.masterData);
    } else {
      roundDuration = 15;
      totalRounds = Math.floor(driveDuration / roundDuration);
    }
    
    let numberOfDriveShifts = this.model.numberOfDriveShifts;
    let remainingRounds = totalRounds;
    let lastShiftEnd = driveStart;
    for (let i = 0; i < numberOfDriveShifts; i++) {
      let numberOfRounds = Math.ceil(remainingRounds / (numberOfDriveShifts - i));
      if (numberOfRounds > remainingRounds) {
        numberOfRounds = remainingRounds;
      }

      let shiftStart = lastShiftEnd;
      let shiftEnd = new Date(shiftStart.getTime() + (numberOfRounds * roundDuration * 60000));
      if (i === numberOfDriveShifts - 1) {
        shiftEnd = driveEnd;
      }
      
      let rounds = this.generateDriveShiftRounds({
        start: shiftStart,
        finish: shiftEnd,
        startTime: this.dateJSToTimeIso(shiftStart),
        endTime: this.dateJSToTimeIso(shiftEnd),
      }, numberOfRounds);
      
      this.model.driveShifts.push({
        key: uniqueId('drive_shift_'),
        label: `Drive Shift ${i + 1}`,
        driveDate: this.drive.driveDate,
        start: shiftStart,
        finish: shiftEnd,
        startTime: this.dateJSToTimeIso(shiftStart),
        endTime: this.dateJSToTimeIso(shiftEnd),
        numberOfRounds: rounds.length,
        rounds: rounds
      })

      remainingRounds = remainingRounds - numberOfRounds;
      lastShiftEnd = shiftEnd;
    }
  }

  generateNumberOfShiftsOptions() {
    const driveHelper = new DriveHelper();

    this.numberOfShiftsOptions = [];

    if(this.canGenerateRounds) {
      const totalRounds = driveHelper.calculatePlateletRounds(this.drive, this.masterData);

      let possibleNumberOfDriveShifts = totalRounds;
      if (possibleNumberOfDriveShifts > 2) {
        possibleNumberOfDriveShifts = 2;
      }

      for (let i = 1; i <= possibleNumberOfDriveShifts; i++) {
        this.numberOfShiftsOptions.push({
          label: i,
          value: i
        });
      }
    } else {
      for (let i = 1; i <= 3; i++) {
        this.numberOfShiftsOptions.push({
          label: i,
          value: i
        });
      }
    }
  }

  generateNumberOfRoundsOptions(driveShift) {
    const driveHelper = new DriveHelper();

    driveShift.numberOfRoundsOptions = [];

    if(!this.canGenerateRounds) { 
      return;
    }

    let driveShiftIndex = this.model.driveShifts.findIndex(item => item.key === driveShift.key);
    let previousDriveShift = this.model.driveShifts[driveShiftIndex - 1];
    let shiftStart = this.newDateTime(this.drive.driveDate, driveShift.startTime, this.masterData.timezoneSidId);
    if(previousDriveShift) {
      const lastPreviousDriveShiftRound = previousDriveShift.rounds[previousDriveShift.rounds.length - 1];
      if(lastPreviousDriveShiftRound && lastPreviousDriveShiftRound.end > shiftStart) {
        shiftStart = lastPreviousDriveShiftRound.end;
      }
    }

    let possibleRounds = driveHelper.calculatePlateletRounds({
      ...driveShift,
      operationType: this.drive.operationType
    }, this.masterData);
      
    for (let i = 0; i <= possibleRounds; i++) {
      driveShift.numberOfRoundsOptions.push({
        label: i,
        value: i
      });
    }
  }

  handleOnChange(event) {
    let targetName = event.target.name;
    let targetValue = getValueFromEvent(event);
    let driveHelper = new DriveHelper();
    if (targetName === 'numberOfDriveShifts') {
      this.model[targetName] = Number(targetValue);
      this.generateDriveShifts();

      this.model.driveShifts.forEach(driveShift => {
        this.generateNumberOfRoundsOptions(driveShift);
      })
      
      driveHelper.splitProjectedProcedures(this.drive, this.model.driveShifts, this.model, PROCEDURE_TYPE._2RBC, this.masterData.timezoneSidId);
      driveHelper.splitProjectedProcedures(this.drive, this.model.driveShifts, this.model, PROCEDURE_TYPE.WB, this.masterData.timezoneSidId);
      driveHelper.splitProjectedProcedures(this.drive, this.model.driveShifts, this.model, PROCEDURE_TYPE.PLATELET, this.masterData.timezoneSidId);
      driveHelper.splitProjectedProcedures(this.drive, this.model.driveShifts, this.model, PROCEDURE_TYPE.PLASMA, this.masterData.timezoneSidId);
      driveHelper.splitScheduledDonors({
        ...this.drive,
        projectedRegisteredDonors: this.model.projectedRegisteredDonors
      }, this.model.driveShifts, this.masterData.timezoneSidId);
    } else {
      this.model[targetName] = targetValue;
    }

    if (targetName === 'projectedRegisteredDonors') {
      this.model.skipAptCalculation = true;
      driveHelper.splitScheduledDonors({
        ...this.drive,
        projectedRegisteredDonors: this.model.projectedRegisteredDonors
      }, this.model.driveShifts, this.masterData.timezoneSidId);
    }

    if(targetName === 'x2rbcProjectedProcedures') {
      driveHelper.splitProjectedProcedures(this.drive, this.model.driveShifts, this.model, PROCEDURE_TYPE._2RBC, this.masterData.timezoneSidId);
    }

    if(targetName === 'wbProjectedProcedures') {
      driveHelper.splitProjectedProcedures(this.drive, this.model.driveShifts, this.model, PROCEDURE_TYPE.WB, this.masterData.timezoneSidId);
    }

    if(targetName === 'plateletProjectedProcedures') {
      driveHelper.splitProjectedProcedures(this.drive, this.model.driveShifts, this.model, PROCEDURE_TYPE.PLATELET, this.masterData.timezoneSidId);
    }

    if(targetName === 'plasmaProjectedProcedures') {
      driveHelper.splitProjectedProcedures(this.drive, this.model.driveShifts, this.model, PROCEDURE_TYPE.PLASMA, this.masterData.timezoneSidId);
    }
  }

  handleOnShiftChange(event) {
    let key = event.currentTarget.dataset['value'];
    let targetName = event.target.name;
    let targetValue = getValueFromEvent(event);
    let driveHelper = new DriveHelper();

    let driveShift = this.model.driveShifts.find(item => item.key === key);
    if (!driveShift) return;

    if (targetName === 'numberOfRounds') {
      driveShift[targetName] = Number(targetValue);
      driveShift.rounds = this.generateDriveShiftRounds(driveShift, driveShift.numberOfRounds);
      driveShift.numberOfRounds = driveShift.rounds.length;
    } else if (targetName === 'startTime') {
      this.model.skipAptCalculation = true;
      driveShift[targetName] = targetValue;
      driveShift.start = targetValue ? this.newDateTime(this.drive.driveDate, targetValue, this.masterData.timezoneSidId) : null;
    } else if (targetName === 'endTime') {
      this.model.skipAptCalculation = true;
      driveShift[targetName] = targetValue;
      driveShift.finish = targetValue ? this.newDateTime(this.drive.driveDate, targetValue, this.masterData.timezoneSidId) : null;
    } else {
      driveShift[targetName] = targetValue;
    }
    
    if(this.canGenerateRounds) {
      const currentDriveShiftIndex = this.model.driveShifts.findIndex(item => item.key === key);
      let needToSplitProjectedProcedures = false;
      for(let i = currentDriveShiftIndex; i < this.model.driveShifts.length; i++) {
        let driveShift = this.model.driveShifts[i];
        this.generateNumberOfRoundsOptions(driveShift);
        
        //check current numberOfRounds is still valid 
        const valid = driveShift.numberOfRoundsOptions.find(option => option.value === driveShift.numberOfRounds);
        let numberOfRounds = driveShift.numberOfRounds;
        if(!valid) {
          numberOfRounds = driveShift.numberOfRoundsOptions.length > 0 ? driveShift.numberOfRoundsOptions[driveShift.numberOfRoundsOptions.length - 1].value : 0;
          needToSplitProjectedProcedures = true;
        }
        driveShift.rounds = this.generateDriveShiftRounds(driveShift, numberOfRounds);
        driveShift.numberOfRounds = driveShift.rounds.length;
      }

      if(needToSplitProjectedProcedures || targetName === 'numberOfRounds') {
        driveHelper.splitProjectedProcedures(this.drive, this.model.driveShifts, this.model, PROCEDURE_TYPE.PLATELET, this.masterData.timezoneSidId);
        driveHelper.splitProjectedProcedures(this.drive, this.model.driveShifts, this.model, PROCEDURE_TYPE.PLASMA, this.masterData.timezoneSidId);
      }

      if(targetName === 'startTime' || targetName === 'endTime') {
        driveHelper.splitProjectedProcedures(this.drive, this.model.driveShifts, this.model, PROCEDURE_TYPE._2RBC, this.masterData.timezoneSidId);
        driveHelper.splitProjectedProcedures(this.drive, this.model.driveShifts, this.model, PROCEDURE_TYPE.WB, this.masterData.timezoneSidId);
      }
    } else {
      if(targetName === 'startTime' || targetName === 'endTime') {
        driveHelper.splitProjectedProcedures(this.drive, this.model.driveShifts, this.model, PROCEDURE_TYPE._2RBC, this.masterData.timezoneSidId);
        driveHelper.splitProjectedProcedures(this.drive, this.model.driveShifts, this.model, PROCEDURE_TYPE.WB, this.masterData.timezoneSidId);
        driveHelper.splitScheduledDonors({
          ...this.drive,
          projectedRegisteredDonors: this.model.projectedRegisteredDonors
        }, this.model.driveShifts, this.masterData.timezoneSidId);
      }
    }
  }

  handleSave() {
    if(!this.validate()) return;

    this.dispatchEvent(new CustomEvent('save', {
      detail: {
        driveShiftsMetadata: this.model
      }
    }));
    this.closeModal();
  }
  
  validate() {
    this.errorMessages = [];

    const allValid = [
      ...this.template.querySelectorAll('lightning-input'), 
      ...this.template.querySelectorAll('c-slwc-select')]
      .reduce((validSoFar, inputCmp) => {
          inputCmp.reportValidity();
          return validSoFar && inputCmp.checkValidity();
      }, true);

    if(this.showProjectedRegisterdDonors) {
      if(this.model.projectedRegisteredDonors <= 0) {
        this.errorMessages.push({
          message: `Total Projected Registered Donors must be > 0.`
        })
      }

      let sumProjectedRegisterdDonors = sumBy(this.model.driveShifts, 'donorsScheduled');
      if(this.model.projectedRegisteredDonors !== sumProjectedRegisterdDonors) {
        this.errorMessages.push({
          message: `Sum of Drive Shift Projected Registered Donors must be equal to Total Projected Registered Donors: ${this.model.projectedRegisteredDonors}.`
        })
      }
    }

    if(this.showWBField) {
      let sumWBProjectedProcedures = sumBy(this.model.driveShifts, 'wbProjectedProcedures');

      if(this.model.wbProjectedProcedures !== sumWBProjectedProcedures) {
        this.errorMessages.push({
          message: `Sum of Drive Shift Whole Blood Procedure Projection must be equal to Total Whole Blood Procedure Projection: ${this.model.wbProjectedProcedures}.`
        })
      }
    }
    
    if(this.showPlateletField) {
      let sumPlateletProjectedProcedures = sumBy(this.model.driveShifts, 'plateletProjectedProcedures');

      if(this.model.plateletProjectedProcedures !== sumPlateletProjectedProcedures) {
        this.errorMessages.push({
          message: `Sum of Drive Shift Platelet Procedure Projection must be equal to Total Platelet Procedure Projection: ${this.model.plateletProjectedProcedures}.`
        })
      }
    }
    
    if(this.showPlasmaField) {
      let sumPlasmaProjectedProcedures = sumBy(this.model.driveShifts, 'plasmaProjectedProcedures');

      if(this.model.plasmaProjectedProcedures !== sumPlasmaProjectedProcedures) {
        this.errorMessages.push({
          message: `Sum of Drive Shift Plasma Procedure Projection must be equal to Total Plasma Procedure Projection: ${this.model.plasmaProjectedProcedures}.`
        })
      }
    }

    return allValid && !this.errorMessages.length;
  }

  /** Date Time Utils **/
  newDateTime(dateIso, timeIso, timezoneSidId) {
    let dateTimeIso = dateIso + 'T' + timeIso;
    let date = new Date(dateTimeIso);

    var invdate = new Date(date.toLocaleString('en-US', {
      timeZone: timezoneSidId
    }));

    var diff = date.getTime() - invdate.getTime();

    return new Date(date.getTime() + diff);
  }

  dateJSToTimeIso(dateJS) {
    if(!dateJS) return null;
    return DateTime.fromJSDate(dateJS, {
      zone: this.masterData.timezoneSidId
    }).toFormat('HH:mm:ss.000');
  }
}