import { LightningElement, api, track } from 'lwc';

export default class SlwcProgressBar extends LightningElement {
  _isOpen = true;
  @api
  get isOpen() {
    return this._isOpen;
  };
  set isOpen(value) {
    this._isOpen = value;

    if (this._isOpen) {
      this.init();
    }
  }

  _progressBarData = {
    totalRecords: 0,
    processedRecords: 0
  };
  @api
  get progressBarData() {
    return this._progressBarData;
  };
  set progressBarData(value) {
    this._progressBarData = value;

    if (this._progressBarData) {
      this.init();
    }
  }
  @api defaultPercentage = 0;
  @api totalPercentage = 100;
  @api isLoadingMode = false;

  @track builtProgressBarData = {};

  get customStyle() {
    return {
      progressBarStyle: [
        `width: ${this.builtProgressBarData.percentage}%`
      ].join(';')
    }
  }

  init = () => {
    let { message, processedRecords, totalRecords } = this.progressBarData;

    processedRecords = processedRecords || 0;
    totalRecords = totalRecords || 0;
    if (message) {
      this.builtProgressBarData.message = message;
    }
    this.builtProgressBarData.totalRecords = totalRecords;
    this.builtProgressBarData.processedRecords = processedRecords;
    this.builtProgressBarData.percentage = totalRecords ? (processedRecords * 100 / totalRecords) : 0;
    this.builtProgressBarData.percentage = (this.defaultPercentage + this.builtProgressBarData.percentage) * 100 / this.totalPercentage;
  }
}