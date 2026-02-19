import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { travelTimeSlotService, travelTimeSlotQueryModel } from 'c/dataService';
import * as slwcDateUtils from "c/slwcDateUtils";
import { cloneDeep } from 'c/lodash';

export default class SlwcTravelTimeSlots extends LightningElement {
	@api recordId;

	@track isEditing = false;
	@track viewData = [];
	@track draftData = [];
	@track slotsData = []; // Store all original travel time slot records (all weekdays) for updates
	@track draftSlotsData = []; // Draft copy of all slots (all weekdays) for editing
	@track showSpinner = false;

	// Configuration Constraints
	maxSlots = 6;
	minDurationMs = 3600000; // 1 Hour
	maxDurationMs = 36000000; // 10 Hours
	weekdays = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

	// Updated columns to point to the formatted 12h values
	viewColumns = [
		{ label: 'Label', fieldName: 'label' },
		{ label: 'Start Time', fieldName: 'formattedStart' }, // Changed to formatted version
		{ label: 'End Time', fieldName: 'formattedEnd' },     // Changed to formatted version
		{ label: 'Duration', fieldName: 'durationDisplay' }
	];

	get dateUtils() {
    return slwcDateUtils.getInstance({
      timezone: TIME_ZONE
    });
  }

	connectedCallback() {
		this.initialize();
	}

	initialize() {
		// Create query model to fetch travel time slots
		let query = new travelTimeSlotQueryModel();
		query.collectionOperationIds = [this.recordId];

		// Fetch data from Salesforce
		this.showSpinner = true;
		let service = new travelTimeSlotService();
		service.query(query)
			.then((result) => {
				if (result && result.length) {
					// Sort slots by weekday and startTime, then assign order numbers
					const weekdayOrder = { 'Sunday': 0, 'Monday': 1, 'Tuesday': 2, 'Wednesday': 3, 'Thursday': 4, 'Friday': 5, 'Saturday': 6 };

					// Sort by weekday first, then by startTime
					result.sort((a, b) => {
						if (weekdayOrder[a.weekday] !== weekdayOrder[b.weekday]) {
							return weekdayOrder[a.weekday] - weekdayOrder[b.weekday];
						}
						return a.startTime - b.startTime;
					});

					// Assign order numbers within each weekday group
					let currentWeekday = null;
					let orderNumber = 0;
					result.forEach(slot => {
						if (slot.weekday !== currentWeekday) {
							currentWeekday = slot.weekday;
							orderNumber = 1;
						} else {
							orderNumber++;
						}
						slot.order = orderNumber;
					});

					// Store all sorted and ordered slots
					this.slotsData = result;

					// Filter for Sunday records only to use as base/template data
					const sundaySlots = result.filter(slot => slot.weekday === 'Sunday');

					if (sundaySlots.length) {
						// Process and format the Sunday data as base/raw data
						this.viewData = sundaySlots.map((slot, index) => {
							// Convert time integer fields (HHMM format) to HH:mm:ss.SSS format
							const startTime = this.timeIntToTime24h(slot.startTime);
							const endTime = this.timeIntToTime24h(slot.endTime);

							return this.processSlotMetrics({
								id: slot.id,
								label: slot.name || `Slot ${index + 1}`,
								startTime: startTime,
								endTime: endTime
							}, index, sundaySlots.length);
						});
					} else {
						// No Sunday data found, use empty array
						this.viewData = [];
					}
				} else {
					// No data found, use empty arrays
					this.slotsData = [];
					this.viewData = [];
				}
			})
			.catch((error) => {
				console.error('Error fetching travel time slots:', error);
				this.dispatchEvent(new ShowToastEvent({
					title: 'Error',
					message: 'Failed to load travel time slots: ' + (error.message || 'Unknown error'),
					variant: 'error'
				}));
				// Fall back to empty array
				this.viewData = [];
			})
			.finally(() => {
				this.showSpinner = false;
			});
	}

	handleEdit() {
		this.draftData = cloneDeep(this.viewData);
		this.draftSlotsData = cloneDeep(this.slotsData);
		this.recalculateLogic();
		this.isEditing = true;
	}

	handleCancel() {
		this.isEditing = false;
		this.draftData = [];
		this.draftSlotsData = [];
	}

	handleInputChange(event) {
		const index = event.target.dataset.index;
		const field = event.target.dataset.field;
		this.draftData[index][field] = event.detail.value;

		// Update draftSlotsData for all weekdays (only for 'label' field)
		if (field === 'label') {
			const newValue = event.detail.value;

			this.weekdays.forEach(weekday => {
				const weekdaySlots = this.draftSlotsData.filter(slot => slot.weekday === weekday);
				if (weekdaySlots.length > index) {
					weekdaySlots[index].name = newValue;
				}
			});
		}
	}

	handleTimeChange(event) {
		const index = parseInt(event.target.dataset.index, 10);
		let newVal = event.detail.value;
		if(newVal && newVal.length === 5) newVal += ':00.000';

		this.draftData[index].endTime = newVal;

		// Update next row's start time
		if (index < this.draftData.length - 1) {
			this.draftData[index + 1].startTime = newVal;
		}

		// Update draftSlotsData for all weekdays
		const newEndTimeInt = this.time24hToTimeInt(newVal);

		this.weekdays.forEach(weekday => {
			const weekdaySlots = this.draftSlotsData.filter(slot => slot.weekday === weekday);
			if (weekdaySlots.length > index) {
				// Update current slot's end time
				weekdaySlots[index].endTime = newEndTimeInt;
				// Update next slot's start time
				if (index < weekdaySlots.length - 1) {
					weekdaySlots[index + 1].startTime = newEndTimeInt;
				}
			}
		});

		this.recalculateLogic();
	}

	handleAddSlot() {
		if (this.draftData.length >= this.maxSlots) return;

		let lastSlot = this.draftData[this.draftData.length - 1];

		let startMs = this.timeToMs(lastSlot.startTime);
		// Default Add 2 hours at split
		let newSplitMs = startMs + 7200000;

		// Update current last slot to end at split
		lastSlot.endTime = this.msToTime24h(newSplitMs);

		// Create new slot for UI
		let newSlot = {
			id: Date.now(),
			label: 'New Slot',
			startTime: lastSlot.endTime,
			endTime: '23:59:00.000'
		};

		this.draftData.push(newSlot);

		// Add corresponding slots for all 7 weekdays in draftSlotsData
		const newStartTimeInt = this.time24hToTimeInt(newSlot.startTime);
		const newEndTimeInt = this.time24hToTimeInt(newSlot.endTime);

		this.weekdays.forEach(weekday => {
			// Find and update the last slot for this weekday
			const weekdaySlots = this.draftSlotsData.filter(slot => slot.weekday === weekday);
			if (weekdaySlots.length) {
				const lastWeekdaySlot = weekdaySlots[weekdaySlots.length - 1];
				lastWeekdaySlot.endTime = this.time24hToTimeInt(lastSlot.endTime);
			}

			// Create new slot for this weekday
			this.draftSlotsData.push({
				id: null, // Will be created on save
				name: 'New Slot',
				startTime: newStartTimeInt,
				endTime: newEndTimeInt,
				weekday: weekday,
				collectionOperationId: this.recordId
			});
		});

		this.recalculateLogic();
	}

	handleDeleteRow(event) {
		const index = parseInt(event.target.dataset.index, 10);
		const deletedSlot = this.draftData[index];

		if (index > 0) {
			let prevSlot = this.draftData[index - 1];
			prevSlot.endTime = deletedSlot.endTime; // Merge
			this.draftData.splice(index, 1);

			if (index < this.draftData.length) {
				this.draftData[index].startTime = prevSlot.endTime;
			}

			// Update draftSlotsData for all weekdays
			const newEndTimeInt = this.time24hToTimeInt(prevSlot.endTime);

			this.weekdays.forEach(weekday => {
				const weekdaySlots = this.draftSlotsData.filter(slot => slot.weekday === weekday);
				if (weekdaySlots.length > index) {
					// Update previous slot's end time
					if (index > 0) {
						weekdaySlots[index - 1].endTime = newEndTimeInt;
					}
					// Remove the deleted slot
					const slotToRemove = weekdaySlots[index];
					const slotIndexInArray = this.draftSlotsData.indexOf(slotToRemove);
					if (slotIndexInArray !== -1) {
						this.draftSlotsData.splice(slotIndexInArray, 1);
					}
					// Update next slot's start time if exists
					if (index < weekdaySlots.length - 1) {
						weekdaySlots[index].startTime = newEndTimeInt;
					}
				}
			});
		} else {
			this.draftData.splice(0, 1);
			this.draftData[0].startTime = '00:00:00.000';

			// Delete first slot for all weekdays
			this.weekdays.forEach(weekday => {
				const weekdaySlots = this.draftSlotsData.filter(slot => slot.weekday === weekday);
				if (weekdaySlots.length) {
					const firstSlot = weekdaySlots[0];
					const slotIndexInArray = this.draftSlotsData.indexOf(firstSlot);
					if (slotIndexInArray !== -1) {
						this.draftSlotsData.splice(slotIndexInArray, 1);
					}
					// Update new first slot's start time
					const newFirstSlot = this.draftSlotsData.filter(slot => slot.weekday === weekday)[0];
					if (newFirstSlot) {
						newFirstSlot.startTime = 0; // 00:00
					}
				}
			});
		}

		this.recalculateLogic();
	}

	handleSave() {
		if(this.hasErrors) return;

		// Save draftSlotsData to Salesforce
		this.showSpinner = true;
		let service = new travelTimeSlotService();
		service.saveList(this.draftSlotsData)
			.then(() => {
				// Update local data after successful save
				this.slotsData = cloneDeep(this.draftSlotsData);
				this.viewData = cloneDeep(this.draftData);
				this.isEditing = false;
				this.draftData = [];
				this.draftSlotsData = [];

				this.dispatchEvent(new ShowToastEvent({
					title: 'Success',
					message: 'Master Schedule saved (Mon-Sun).',
					variant: 'success'
				}));
			})
			.catch((error) => {
				console.error('Error saving travel time slots:', error);
				this.dispatchEvent(new ShowToastEvent({
					title: 'Error',
					message: 'Failed to save travel time slots: ' + (error.message || 'Unknown error'),
					variant: 'error'
				}));
			})
			.finally(() => {
				this.showSpinner = false;
			});
	}

	// --- CALCULATIONS & VALIDATION ---

	recalculateLogic() {
		this.draftData = this.draftData.map((slot, index) => {
			return this.processSlotMetrics(slot, index, this.draftData.length);
		});
	}

	// Unified logic helper for both View and Edit modes
	processSlotMetrics(slot, index, totalLength) {
		const isLast = index === totalLength - 1;

		// Enforce Boundaries
		if(index === 0) slot.startTime = '00:00:00.000';
		if(isLast) slot.endTime = '23:59:00.000';

		// Calc Duration
		let startMs = this.timeToMs(slot.startTime);
		let endMs = this.timeToMs(slot.endTime);

		if(slot.endTime.startsWith('23:59')) endMs = 86400000; // 24 hours

		let diff = endMs - startMs;
		let isValid = true;
		let errorMsg = '';

		if(diff < this.minDurationMs) {
			isValid = false;
			errorMsg = 'Min 1 hour';
		} else if (diff > this.maxDurationMs) {
			isValid = false;
			errorMsg = 'Max 10 hours';
		}

		return {
			...slot,
			indexDisplay: index + 1,
			isLastRow: isLast,
			formattedStart: this.msToTime12h(startMs),
			formattedEnd: this.msToTime12h(endMs),

			durationDisplay: (diff / 3600000).toFixed(1) + ' hrs',
			durationIcon: isValid ? 'utility:clock' : 'utility:warning',
			badgeClass: isValid ? 'slds-theme_success' : 'slds-theme_error',
			validationClass: isValid ? '' : 'slds-has-error',
			hasError: !isValid,
			errorMsg: errorMsg
		};
	}

	// --- HELPERS ---

	timeToMs(timeStr) {
		if(!timeStr) return 0;
		let parts = timeStr.split(':');
		return (parseInt(parts[0], 10) * 3600000) + (parseInt(parts[1], 10) * 60000);
	}

	// Converts time integer (HHMM format) to HH:mm:ss.SSS format
	// Examples: 700 -> "07:00:00.000", 1030 -> "10:30:00.000", 2359 -> "23:59:00.000"
	timeIntToTime24h(timeInt) {
		if (!timeInt && timeInt !== 0) return '00:00:00.000';

		// Extract hours and minutes from HHMM format
		let hours = Math.floor(timeInt / 100);
		let minutes = timeInt % 100;

		return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:00.000`;
	}

	// Converts HH:mm:ss.SSS format back to time integer (HHMM format)
	// Examples: "07:00:00.000" -> 700, "10:30:00.000" -> 1030, "23:59:00.000" -> 2359
	time24hToTimeInt(timeStr) {
		if (!timeStr) return 0;

		let parts = timeStr.split(':');
		let hours = parseInt(parts[0], 10);
		let minutes = parseInt(parts[1], 10);

		return (hours * 100) + minutes;
	}

	// Converts MS back to HH:mm:ss.000 for the system values
	msToTime24h(duration) {
		let hours = Math.floor(duration / 3600000);
		let minutes = Math.floor((duration % 3600000) / 60000);
		return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:00.000`;
	}

	// NEW: Converts MS to "8:00 AM" format for Display
	msToTime12h(duration) {
		// Handle 24h/Midnight edge case
		if (duration >= 86400000 - 60000) return '11:59 PM'; // Handle 23:59 specifically
		if (duration >= 86400000) return '12:00 AM'; // Next day midnight

		let totalMins = Math.floor(duration / 60000);
		let hours = Math.floor(totalMins / 60);
		let mins = totalMins % 60;

		let ampm = hours >= 12 ? 'PM' : 'AM';

		hours = hours % 12;
		hours = hours ? hours : 12; // the hour '0' should be '12'

		let strMin = mins < 10 ? '0' + mins : mins;

		return `${hours}:${strMin} ${ampm}`;
	}

	get hasErrors() { return this.draftData.some(d => d.hasError); }
	get disableAddButton() { return this.draftData.length >= this.maxSlots; }
	get isSingleRow() { return this.draftData.length <= 1; }
	get limitTextClass() { return this.disableAddButton ? 'slds-text-color_error' : 'slds-text-color_weak'; }
}
