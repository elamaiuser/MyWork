import TIME_ZONE from "@salesforce/i18n/timeZone";
import USER_ID from "@salesforce/user/Id";
import {
	driveShiftQueryModel, driveShiftTradeService, resourceQueryModel, resourceService,
  sObjectType
} from "c/dataService";
import { DateTime } from "c/luxon";
import * as slwcDateUtils from "c/slwcDateUtils";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { LightningElement, track, api } from "lwc";
import { DRIVE_SHIFT_TRADE_STATUS, DRIVE_SHIFT_TRADE_TYPE } from 'c/slwcConstants';
import { classNames } from 'c/slwcUtils';

const MODE = {
	LIST_VIEW: 'listView',
	NEW_REQUEST: 'newRequest'
}

export default class SlwcDriveShiftTradeList extends LightningElement {
	@api fullScreen = false;

  @track timezoneSidId = TIME_ZONE;
  @track filters = {
    startDate: null,
    endDate: null
  };
  @track allDriveShiftTrades = [];
  @track filteredDriveShiftTrades = [];
  @track showSpinner = false;
	@track confirmModalData = {};
	@track driveShiftTradeModalData = {};
  @track acknowledgeConfirmModalData = {};
	@track userResource = null;

	@track mode = MODE.LIST_VIEW;

	get customClass() {
    return {
      modal: classNames('slds-grid slds-grid_vertical', {
        'full-screen': this.fullScreen
      })
    }
  }
	
  get dateUtils() {
    return slwcDateUtils.getInstance({
      timezone: TIME_ZONE
    });
  }

	get showListViewPage() {
		return this.mode === MODE.LIST_VIEW;
	}

	get showNewRequestPage() {
		return this.mode === MODE.NEW_REQUEST;
	}

  connectedCallback() {
		this.init();
  }

  init() {
		let query = new resourceQueryModel();
    query.userIds = [USER_ID]
    query.subQueryIndicator = sObjectType.RESOURCE_OVERRIDE;
    // Quan
    // query.userIds = ['0053F000003lc8UQAQ']
    // Hieu
    // query.userIds = ["0053F000003lc8AQAQ"];
    // Amanda 
    // query.userIds = ["00505000001tAf4AAE"];

    this.showLoading();
    let service = new resourceService();
    service.query(query).then((rawData) => {
      if(!rawData || !rawData.length) {
        this.showConfirmModal({
          mode: 'error',
          title: 'Error',
          message: 'This screen cannot be loaded as you do not have an Active Resource record associated. Please contact your administrator for assistance.',
          confirmBtnLabel: 'none',
          cancelBtnLabel: 'none'
        });

        return;
      }

      this.userResource = rawData[0];

			this.clear();
			return this.fetchDriveShiftTrades();
    })
    .catch(error => this.exceptionHandler(error))
    .finally(this.hideLoading);
  }
  
  clear() {
		this.allDriveShiftTrades = [];
		this.filteredDriveShiftTrades = [];
    this.filters = {
      startDate: null,
      endDate: null
    };
    this.showSpinner = false;

    if (!this.filters.startDate || !this.filters.endDate) {
      const firstDay = this.dateUtils.getFirstDayValue();
      this.filters.startDate = this.dateUtils
        .startOfWeek(DateTime.local(), firstDay)
        .toISODate();
      this.filters.endDate = DateTime.fromISO(this.filters.startDate)
        .plus({
          day: 6
        })
        .toISODate();
    }
  }

  // LOADING
  exceptionHandler = (error) => {
    this.dispatchEvent(new ShowToastEvent({
        message: error.message,
        variant: 'error',
        mode: 'dismissable',
    }));
  }

  showLoading = () => {
    this.showSpinner = true;
  };

  hideLoading = () => {
    this.showSpinner = false;
  };

  filterDriveShiftTrades() {
    this.filteredDriveShiftTrades = this.allDriveShiftTrades;
  }
  
  handleOnChangeFilter(event) {
    if (event.type === "weekdatechange") {
      this.filters.startDate = event.detail.startDate;
      this.filters.endDate = event.detail.endDate;
    }

		this.fetchDriveShiftTrades();
  }

	fetchDriveShiftTrades() {
		let service = new driveShiftTradeService();
		let query = new driveShiftQueryModel();
    query.tradingEventStartDate = this.filters.startDate;
    query.tradingEventEndDate = this.filters.endDate;
		query.resourceIds = [this.userResource.id];
    query.onlyOneSideTrade = false;
    query.orderBy = 'submissionStartDate';
    query.orderAscending = 'asc';

		this.showLoading();
		return service.query(query)
			.then((driveShiftTrades = []) => {
				this.allDriveShiftTrades = driveShiftTrades.map(item => {
					item.canAcknowledge = (
            [DRIVE_SHIFT_TRADE_STATUS.WAITING_FOR_TRADING_STAFF_ACKNOWLEDGE].includes(item.status) && item.tradingStaffId === this.userResource.id || 
            [DRIVE_SHIFT_TRADE_STATUS.WAITING_FOR_REQUESTING_STAFF_ACKNOWLEDGE].includes(item.status) && item.requestingStaffId === this.userResource.id
          );
          item.canCancel = [
            DRIVE_SHIFT_TRADE_STATUS.SUBMITTED, DRIVE_SHIFT_TRADE_STATUS.PENDING_APPROVAL,
            DRIVE_SHIFT_TRADE_STATUS.WAITING_FOR_TRADING_STAFF_ACKNOWLEDGE,
            DRIVE_SHIFT_TRADE_STATUS.WAITING_FOR_REQUESTING_STAFF_ACKNOWLEDGE
          ].includes(item.status) &&
            item.requestingStaffId === this.userResource.id;
					
					return item;
				});
				this.filterDriveShiftTrades();
			})
			.catch(e => this.exceptionHandler(e))
			.finally(() => this.hideLoading())
	}

	handleNewDriveShiftTrade() {
		this.showDriveShiftTradeModal();
	}

	handleAcknowledgeButton(event) {
		const recordId = event.currentTarget.dataset['id'];
		const record = this.allDriveShiftTrades.find(item => item.id === recordId);
		if(!record) return;

    this.showAcknowledgeConfirmModal(record);
	}

	handleCancelButton(event) {
		const recordId = event.currentTarget.dataset['id'];
		const record = this.allDriveShiftTrades.find(item => item.id === recordId);
		if(!record) return;

		this.showConfirmModal({
			title: 'Cancel Shift Trade',
			message: 'Do you want to cancel this shift trade?',
			onClose: (result) => {
					this.hideConfirmModal();
					if (result) {
						this.showLoading();
						let service = new driveShiftTradeService();
						service.save({
							id: record.id,
							status: 'Cancelled'
						})
						.then((result) => {
							if(!result.success) throw result;
							return this.fetchDriveShiftTrades();
						})
						.catch(error => this.exceptionHandler(error))
						.finally(this.hideLoading);
					}
			},
			confirmBtnLabel: 'Yes',
			cancelBtnLabel: 'No'
		});
	}

  /** Acknowledge Confirm Modal */
  showAcknowledgeConfirmModal(driveShiftTrade) {
    this.acknowledgeConfirmModalData = {
      isOpen: true,
      driveShiftTrade
    }
  }

  closeAcknowledgeConfirmModal() {
    this.acknowledgeConfirmModalData = {};
  }

  saveAcknowledgeConfirmModal(event) {
    const driveShiftTrade = this.acknowledgeConfirmModalData.driveShiftTrade;
    const { 
      id, requestingStaffTATAcknowledge, requestingStaffGMHAcknowledge, requesterRelocatedAcknowledge, requesterUnavailableForCOAcknowledge,
      tradingStaffTATAcknowledge, tradingStaffGMHAcknowledge, traderRelocatedAcknowledge, traderUnavailableForCOAcknowledge
    } = event.detail;
    this.showLoading();
    let service = new driveShiftTradeService();
    service.save({
      id: id,
      requestingStaffTATAcknowledge,
      requestingStaffGMHAcknowledge,
      requesterRelocatedAcknowledge,
      requesterUnavailableForCOAcknowledge,
      tradingStaffTATAcknowledge,
      tradingStaffGMHAcknowledge,
      traderRelocatedAcknowledge,
      traderUnavailableForCOAcknowledge
    })
    .then((result) => {
      if(!result.success) throw result;
      return service.autoProcessRequest({
        request: {
          ...driveShiftTrade,
          requestingStaffTATAcknowledge,
          requestingStaffGMHAcknowledge,
          requesterRelocatedAcknowledge,
          requesterUnavailableForCOAcknowledge,
          tradingStaffTATAcknowledge,
          tradingStaffGMHAcknowledge,
          traderRelocatedAcknowledge,
          traderUnavailableForCOAcknowledge
        }
      });
    }).then((result) => {
      if(!result.success) throw result;
      return this.fetchDriveShiftTrades();
    })
    .catch(error => this.exceptionHandler(error))
    .finally(() => {
      this.closeAcknowledgeConfirmModal();
      this.hideLoading()
    });
  }

	/** Drive Shift Trade Modal **/
	showDriveShiftTradeModal() {
    this.mode = MODE.NEW_REQUEST;
  }

	closeDriveShiftTradeModal(event) {
		const saved = !!event.detail.result;
		if(saved) {
			this.fetchDriveShiftTrades();
		}

		this.mode = MODE.LIST_VIEW;
	}

  /** Confirm Modal **/	
  showConfirmModal(confirmModalData) {
    this.confirmModalData = {...confirmModalData,
        isOpen: true
    }
  }

  hideConfirmModal() {
      this.confirmModalData = {};
  }
}