import { LightningElement, api, track } from 'lwc';

export default class SlwcDriveOptimizeSettingsForm extends LightningElement {
  _settings;

  @track softConstraints = [];

  @api
  get settings() {
    return this._settings;
  }

  set settings(value) {
    this._settings = value || [];
    this.softConstraints = this._settings.filter((setting) => setting.constraintType === 'Soft Constraint');
  }

  handleOnChange(event) {
    event.stopPropagation();

    const onchangeEvent = new CustomEvent('change', {
      detail: {
        id: event.detail.id,
        value: event.detail.value
      },
    });
    this.dispatchEvent(onchangeEvent);
  }

  handleResetScoringFactors() {
    const onchangeEvent = new CustomEvent('reset');
    this.dispatchEvent(onchangeEvent);
  }
}