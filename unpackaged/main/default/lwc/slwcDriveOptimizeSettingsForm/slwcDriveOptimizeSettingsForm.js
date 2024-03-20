import { LightningElement, api, track } from 'lwc';
import * as slwcUtils from 'c/slwcUtils';

export default class SlwcDriveOptimizeSettingsForm extends LightningElement {
  _settings;
  @api
  get settings() {
    return this._settings;
  }
  set settings(value) {
    this._settings = value;

    if(value) {
      this.init();
    }
  }

  @api showSaveButton = false;

  @track scoringFactors = [
    { label: '--None--', value: ''},
    { label: 'High', value: 'High' },
    { label: 'Medium', value: 'Medium' },
    { label: 'Low', value: 'Low' }
  ];

  init() {
    const onchangeEvent = new CustomEvent('change', {
      detail: {
        accountPreferencesScore: this.settings.accountPreferencesScore || '',
        locationPreferencesScore: this.settings.locationPreferencesScore || '',
        geographicPreferencesScore: this.settings.geographicPreferencesScore || '',
        seniorityRankScore: this.settings.seniorityRankScore || ''
      }
    });
    this.dispatchEvent(onchangeEvent);
  };

  handleOnChange(event) {
    event.stopPropagation();

    let newValue = slwcUtils.getValueFromEvent(event);
    if(['accountPreferencesScore', 'locationPreferencesScore', 'geographicPreferencesScore', 'seniorityRankScore'].includes(event.target.name)) {
      newValue = newValue || '';
    }

    const onchangeEvent = new CustomEvent('change', {
      detail: {
        [event.target.name]: newValue
      },
    });
    this.dispatchEvent(onchangeEvent);
  }

  handleResetScoringFactors() {
    const onchangeEvent = new CustomEvent('change', {
      detail: {
        accountPreferencesScore: '',
        locationPreferencesScore: '',
        geographicPreferencesScore: '',
        seniorityRankScore: ''
      }
    });
    this.dispatchEvent(onchangeEvent);
  }

  handleSave() {
    const saveEvent = new CustomEvent('save', {
      detail: {},
    });
    this.dispatchEvent(saveEvent);
  }
}