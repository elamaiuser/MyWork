import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { adminConsoleService } from 'c/dataService';
import TIME_ZONE from '@salesforce/i18n/timeZone';

export default class SlwcAdminConsoleManageSchedule extends LightningElement {
  @api isReadonly = false;
  @track timezoneSidId = TIME_ZONE;
  @track showSpinner = false;
  @track scheduleList = [];

  get showEmptyMessage() {
    return !this.scheduleList || !this.scheduleList.length;
  }

  connectedCallback() {
    this.fetchScheduleList();
  }

  exceptionHandler = (error) => {
    if (error && error.message) {
      this.dispatchEvent(new ShowToastEvent({
        message: error.message,
        variant: 'error',
        mode: 'dismissable',
      }));
    }
  }

  showLoading = () => {
    this.showSpinner = true;
  }

  hideLoading = () => {
    this.showSpinner = false;
  }

  fetchScheduleList = () => {
    const transformData = (item) => {
      return {
        ...item,
        disableExecuteBtn: false
      }
    }

    this.showLoading();
    let service = new adminConsoleService();
    service.getScheduleList()
      .then((result) => {
        this.scheduleList = (result.returnedData || []).map(transformData);
      })
      .catch(e => this.exceptionHandler(e))
      .finally(() => this.hideLoading());
  }

  executeSchedule = (schedule) => {
    this.showLoading();
    let service = new adminConsoleService();
    service.executeSchedule({
      request: { 
        'scheduleName': schedule.name
      }
    })
    .then((result = []) => {
      if (!result || !result.success) throw result;

      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Success',
          message: 'Executed successfully.',
          variant: 'success'
        })
      );
    })
    .catch(e => this.exceptionHandler(e))
    .finally(() => this.hideLoading());
  }
  
  handleRefreshBtn = () => {
    this.fetchScheduleList();
  }

  handleExecuteBtn = (event) => {
    const id = event.currentTarget.dataset['id'];
    const item = this.scheduleList.find(item => item.id === id);
    if(!item) return;

    this.executeSchedule(item);
  }
}