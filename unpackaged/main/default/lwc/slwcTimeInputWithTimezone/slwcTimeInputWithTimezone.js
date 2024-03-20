import { LightningElement, track, api } from 'lwc';
import { DateTime } from 'c/luxon';
import { classNames } from 'c/slwcUtils';
import * as slwcUtils from 'c/slwcUtils';
import TIME_ZONE from '@salesforce/i18n/timeZone';

export default class SlwcTimeInputWithTimezone extends LightningElement {
  @api noLabel = false;
  @api readOnly = false;
  @api disabled = false;

  @track _inputDate;
  @api 
  set inputDate(value) {
    this._inputDate = value;
    setTimeout(() => {
      this.populateTimezoneAbbr();
    })
  }
  get inputDate() {
    return this._inputDate;
  }

  @track _timezone;
  @api 
  set timezone(value) {
    this._timezone = value;
    setTimeout(() => {
      this.populateTimezoneAbbr();
    })
  }
  get timezone() {
    return this._timezone;
  }

  @track timezoneAbbr;

  get isMobile(){
    return slwcUtils.isMobile();
  }

  get customClass() {
    return {
      wrapper: classNames('wrapper slds-form-element', {
        'no-label': this.noLabel,
        'read-only': this.readOnly,
        'disabled': this.disabled,
        'is-mobile': this.isMobile
      })
    }
  }

  populateTimezoneAbbr = () => {
    let inputDate = this.inputDate; 
    let timezone = this.timezone;

    if (!timezone) {
      timezone = TIME_ZONE;
    }
    if (!inputDate) {
      inputDate = DateTime.fromJSDate(new Date(), {
        zone: timezone
      }).toISODate();
    }
    else {
      // try {
        inputDate = DateTime.fromISO(inputDate, {
          zone: timezone
        }).toISODate();
      // } catch (e) {
      //   alert(e);
      // }
    }

    this.timezoneAbbr = DateTime.fromISO(inputDate, {
      zone: timezone
    }).toFormat('ZZZZ');
  }
}