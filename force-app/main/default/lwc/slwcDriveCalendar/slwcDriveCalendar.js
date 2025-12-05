import { LightningElement, track, wire, api } from "lwc";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import TIME_ZONE from "@salesforce/i18n/timeZone";
import { CurrentPageReference } from "lightning/navigation";
import { DateTime } from "c/luxon";
import { groupBy, uniqueId, uniq } from 'c/lodash';
import { calendarMonthHelper, planDriveDateHelper } from "c/slwcHelpers";
import { classNames, isNullOrEmpty } from "c/slwcUtils";
import {
    activityQueryModel,
    activityService, 
    driveQueryModel,
    driveService, 
    holidayService, 
    calendarMessageService,
    productGoalQueryModel,
    productGoalService, 
    staffingConstraintQueryModel,
    staffingConstraintService,
    operationDriveLimitService,
    operationDriveLimitQueryModel,
    sObjectType,
    territoryQueryModel,
    territoryService,
    userService
} from 'c/dataService';
import productGoalCalendar from './productGoalCalendar.html';
import productivityCalendar from './productivityCalendar.html';
import { ASSET_TYPE, DRIVE_TYPE, OPERATION_DRIVE_LIMIT_TYPE, DRIVE_OPERATION_TYPE, RESOURCE_TYPE } from 'c/slwcConstants';
import { DriveHelper } from 'c/slwcDriveGenerator';
import * as slwcDateUtils from 'c/slwcDateUtils';
import * as slwcAvailator from 'c/slwcAvailator';

const DEFAULT_CALENDAR_SETTINGS = {
    timezone: TIME_ZONE,
    firstDay: 0
};

export default class SlwcDriveCalendar extends LightningElement {
    @wire(CurrentPageReference) pageRef;

    @api defaultDate = null;
    @api displayMode;
    @api isReadonly = false;

    _filters = null;
    @api
    get filters() {
        return this._filters;
    }
    set filters(value) {
        this._filters = value;

        if (this.initialized) {
            this.handleRefreshCalendar();
        }
    }
    
    @track initialized = false;
    @track showSpinner = false;
    @track assetMapByDateAndType = null;
    @track staffingConstraintsMapByDate = null;
    @track drivesMapByDate = null;
    @track activitiesMapByDate = null;
    @track productGoalsByDate = null;
    @track selectedMonth;
    @track holidays = [];
    @track monthSummary = null;
    @track calendarWeeks = [];
    @track driveLimits;
    @track loginUser;
    @track isTimeBlockApplied;

    @track confirmModalData = {};

    territoriesMapById = null;

    driveHelper = new DriveHelper();
    contentMap = {
        "productGoalCalendar": productGoalCalendar,
        "productivityCalendar": productivityCalendar
    }

    _calendarHelper = null;
    get calendarHelper() {
        if (!this._calendarHelper) {
            this._calendarHelper = new calendarMonthHelper(DEFAULT_CALENDAR_SETTINGS);
        }
        return this._calendarHelper;
    }

    _planDriveHelper = null;
    get planDriveHelper() {
        if (!this._planDriveHelper) {
        this._planDriveHelper = new planDriveDateHelper(DEFAULT_CALENDAR_SETTINGS);
        }
        return this._planDriveHelper;
    }

    get dateUtils() {
        return slwcDateUtils.getInstance({
          timezone: TIME_ZONE
        })
    }

    get customClass() {
        return {
            staffingDetails: classNames('date-slot staffing-details slds-grid slds-wrap slds-grid_align-spread', {
                'two-row': this.showFixedSiteStaffingDetails && this.showMobileStaffingDetails
            })
        }
    }

    get showFixedSiteStaffingDetails() {
        if(!this.filters) return true;
        if(!this.filters.driveOperationTypes || !this.filters.driveOperationTypes.length) return true;
        return this.filters.driveOperationTypes.includes(DRIVE_OPERATION_TYPE.FIXED_SITE);
    }

    get showMobileStaffingDetails() {
        if(!this.filters) return true;
        if(!this.filters.driveOperationTypes || !this.filters.driveOperationTypes.length) return true;
        return this.filters.driveOperationTypes.includes(DRIVE_OPERATION_TYPE.MOBILE) || this.filters.driveOperationTypes.includes(DRIVE_OPERATION_TYPE.NIFS);
    }

    get today() {
        return DateTime.local().toJSDate();
    }

    get weekDays() {
        let result = this.calendarHelper.buildWeekDays();
        result.push("Week");
        return result;
    }

    get territoryKeys() {
        if (!this.filters || !this.filters.collectionOperationValues) return [];
        return this.filters.collectionOperationValues.territoryCollectionOperations.map(item => `${item.territoryId}:${item.collectionOperationId}`);
    }

    get collectionOperations() {
        if (!this.filters || !this.filters.collectionOperationValues) return [];
        return this.filters.collectionOperationValues.territoryCollectionOperations.map(item => item.collectionOperation);
    }

    connectedCallback() {
        this.retrieveLoginUser();
        this.calendarWeeks = this.buildCalendarWeeks();
    }
    
    renderedCallback() {
        if (!this.initialized) {
          this.initialized = true;
        }
    }

    render() {
        return this.contentMap[this.displayMode];
    }

    disconnectedCallback() {
    }


    isValidFilters() {
        return this.filters && this.filters.selectedMonth 
                && this.territoryKeys && this.territoryKeys.length;
    }

    isValidData() {
        if (this.displayMode == "productGoalCalendar") {
            return this.assetMapByDateAndType && this.staffingConstraintsMapByDate && this.drivesMapByDate && this.productGoalsByDate;
        } else if (this.displayMode == "productivityCalendar") {
            return this.drivesMapByDate;
        }
    }

    retrieveLoginUser() {
        let service = new userService();
        return service.getLoginUser()
        .then((result) => {
            this.loginUser = result.returnedData;
        })
    }

    hasAccess(){
        return this.driveHelper.isAdminUser(this.loginUser) || this.driveHelper.isOnlyAPSUser(this.loginUser);
    }

    handleRefreshCalendar() {
        const selectedTimeBlockIds = this.filters.collectionOperationValues.timeBlocks?.map(item => item.value);
        this.isTimeBlockApplied = !!selectedTimeBlockIds?.length;

        this.isFixedSiteDisabled = this.filters.driveOperationTypes?.includes(DRIVE_OPERATION_TYPE.FIXED_SITE);
        this.selectedMonth = this.filters.selectedMonth;

        if (this.displayMode == "productGoalCalendar") {
            this.rebuildProductGoalCalendar();
        }
        else if (this.displayMode == "productivityCalendar") {
            this.rebuildProductivityCalendar();
        }
    }
    
    buildMonthSummary = () => {
        if (this.displayMode == 'productGoalCalendar') {
            let monthSummary = {
                totalProductGoal: 0,
                totalProductBooked: 0,
                percentOfGoal: 0
            };
            this.calendarWeeks.forEach(week => {
                week.days.forEach(day => {
                    if (day.isOutOfMonth === false) {
                        if (day.slot) {
                            monthSummary.totalProductGoal += day.slot.noOfProductGoal;
                            monthSummary.totalProductBooked += day.slot.noOfProductBooked;
                        }
                    }
                });
            });
            if (monthSummary.totalProductGoal) {
                monthSummary.percentOfGoal = Number(monthSummary.totalProductBooked / monthSummary.totalProductGoal).toFixed(2);
            }
            monthSummary.productGoalIndicatorClass = classNames('day-of-slot slds-col slds-size_1-of-3 slds-text-align_center', {
                'day-of-slot__green': monthSummary.percentOfGoal >= 1,
                'day-of-slot__red': monthSummary.percentOfGoal < 1,
            });
            return monthSummary;
        }
        else {
            let monthSummary = {
                totalDrives: 0,
                totalDriveProductivity: 0,
                averageProductivity: 0,
                noOfHighProductivityDrives: 0,
                totalHighProductivity: 0,
                averageHighProductivityDrives: 0,
                noOfMidProductivityDrives: 0,
                totalMidProductivity: 0,
                averageMidProductivityDrives: 0,
                noOfLowProductivityDrives: 0,
                totalLowProductivity: 0,
                averageLowProductivityDrives: 0
            }
            this.calendarWeeks.forEach(week => {
                week.days.forEach(day => {
                    if (day.isOutOfMonth === false) {
                        if (day.slot) {
                            monthSummary.totalDrives += day.slot.totalDrives;
                            monthSummary.totalDriveProductivity += day.slot.totalDriveProductivity;
                            monthSummary.noOfHighProductivityDrives += day.slot.noOfHighProductivityDrives;
                            monthSummary.totalHighProductivity += day.slot.totalHighProductivity;
                            monthSummary.noOfMidProductivityDrives += day.slot.noOfMidProductivityDrives;
                            monthSummary.totalMidProductivity += day.slot.totalMidProductivity;
                            monthSummary.noOfLowProductivityDrives += day.slot.noOfLowProductivityDrives;
                            monthSummary.totalLowProductivity += day.slot.totalLowProductivity;
                        }
                    }
                });
            });
            monthSummary.averageProductivity = this.standardlizeNumber(monthSummary.totalDriveProductivity / monthSummary.totalDrives);
            if (monthSummary.totalHighProductivity) {
                monthSummary.averageHighProductivityDrives = this.standardlizeNumber(monthSummary.totalHighProductivity / monthSummary.noOfHighProductivityDrives);
            }
            if (monthSummary.totalMidProductivity) {
                monthSummary.averageMidProductivityDrives = this.standardlizeNumber(monthSummary.totalMidProductivity / monthSummary.noOfMidProductivityDrives);
            }
            if (monthSummary.totalLowProductivity) {
                monthSummary.averageLowProductivityDrives = this.standardlizeNumber(monthSummary.totalLowProductivity / monthSummary.noOfLowProductivityDrives);
            }
            monthSummary.summaryClass = classNames('day-of-slot slds-col slds-size_1-of-2 slds-text-align_center', {
                'day-of-slot__grey': monthSummary.totalDriveProductivity > 0
            });
            monthSummary.highProductivityClass = classNames('day-of-slot slds-col slds-size_1-of-2 slds-text-align_center', {
                'day-of-slot__green': monthSummary.totalHighProductivity > 0
            });
            monthSummary.midProductivityClass = classNames('day-of-slot slds-col slds-size_1-of-2 slds-text-align_center', {
                'day-of-slot__amber': monthSummary.totalMidProductivity > 0
            });
            monthSummary.lowProductivityClass = classNames('day-of-slot slds-col slds-size_1-of-2 slds-text-align_center', {
                'day-of-slot__red': monthSummary.totalLowProductivity > 0
            });

            return monthSummary;
        }
    }

    buildCalendarWeeks = () => {
        let selectedMonth = this.selectedMonth || DateTime.local().toISODate();
        if (!selectedMonth) return [];
        
        let calendarWeeks = this.calendarHelper.buildCalendarWeeks(selectedMonth, this.today, this.holidays, this.calendarMessages);
        calendarWeeks.forEach(week => {
            week.startDateIso = week.days[0].dateIso;
            let weekSummary = {
                key: week.key + "summary",
                isWeekSummary: true,
            };
            if (this.isValidFilters() && this.isValidData()) {
                week.days.forEach(day => {
                    if (this.displayMode == 'productGoalCalendar') {
                        this.buildSlot_ProductGoalCalendar(day);
                    }
                    else if (this.displayMode == 'productivityCalendar') {
                        this.buildSlot_ProductivityCalendar(day);
                    }
                    let holidays = [];
                    (day.holidays || []).forEach((holiday) => {
                        holidays.push(holiday.name);
                    });
                    if (holidays && holidays.length) {
                        day.holidays = holidays.join('; ');
                    }

                    let calendarMessages = [];
                    (day.calendarMessages || []).forEach((calendarMessage) => {
                        calendarMessages.push(calendarMessage.message);
                    });
                    if (calendarMessages && calendarMessages.length) {
                        day.calendarMessages = calendarMessages.join('; ');
                    }
                });

                if (this.displayMode == 'productGoalCalendar') {
                    weekSummary.slot = {
                        totalProductGoal: 0,
                        totalProductBooked: 0,
                        percentOfGoal: 0
                    };
                    week.days.forEach((day) => {
                        weekSummary.slot.totalProductGoal += day.slot.noOfProductGoal;
                        weekSummary.slot.totalProductBooked += day.slot.noOfProductBooked;
                    });
                    if (weekSummary.slot.totalProductGoal) {
                        weekSummary.slot.percentOfGoal = Number(weekSummary.slot.totalProductBooked / weekSummary.slot.totalProductGoal).toFixed(2);
                    }
                    weekSummary.slot.productGoalIndicatorClass = classNames('day-of-slot slds-col slds-size_1-of-3 slds-text-align_center', {
                        'day-of-slot__green': weekSummary.slot.percentOfGoal >= 1,
                        'day-of-slot__red': weekSummary.slot.percentOfGoal < 1,
                    });
                }
                else if (this.displayMode == 'productivityCalendar') {
                    weekSummary.slot = {
                        totalDrives: 0,
                        totalDriveProductivity: 0,
                        averageProductivity: 0,
                        noOfHighProductivityDrives: 0,
                        totalHighProductivity: 0,
                        averageHighProductivityDrives: 0,
                        noOfMidProductivityDrives: 0,
                        totalMidProductivity: 0,
                        averageMidProductivityDrives: 0,
                        noOfLowProductivityDrives: 0,
                        totalLowProductivity: 0,
                        averageLowProductivityDrives: 0
                    };
                    week.days.forEach((day) => {
                        weekSummary.slot.totalDrives += day.slot.totalDrives;
                        weekSummary.slot.totalDriveProductivity += day.slot.totalDriveProductivity;
                        weekSummary.slot.noOfHighProductivityDrives += day.slot.noOfHighProductivityDrives;
                        weekSummary.slot.totalHighProductivity += day.slot.totalHighProductivity;
                        weekSummary.slot.noOfMidProductivityDrives += day.slot.noOfMidProductivityDrives;
                        weekSummary.slot.totalMidProductivity += day.slot.totalMidProductivity;
                        weekSummary.slot.noOfLowProductivityDrives += day.slot.noOfLowProductivityDrives;
                        weekSummary.slot.totalLowProductivity += day.slot.totalLowProductivity;
                    });
                    weekSummary.slot.averageProductivity = this.standardlizeNumber(weekSummary.slot.totalDriveProductivity / weekSummary.slot.totalDrives);
                    if (weekSummary.slot.totalHighProductivity) {
                        weekSummary.slot.averageHighProductivityDrives = this.standardlizeNumber(weekSummary.slot.totalHighProductivity / weekSummary.slot.noOfHighProductivityDrives);
                    }
                    if (weekSummary.slot.totalMidProductivity) {
                        weekSummary.slot.averageMidProductivityDrives = this.standardlizeNumber(weekSummary.slot.totalMidProductivity / weekSummary.slot.noOfMidProductivityDrives);
                    }
                    if (weekSummary.slot.totalLowProductivity) {
                        weekSummary.slot.averageLowProductivityDrives = this.standardlizeNumber(weekSummary.slot.totalLowProductivity / weekSummary.slot.noOfLowProductivityDrives);
                    }
                    weekSummary.slot.summaryClass = classNames('day-of-slot slds-col slds-size_1-of-2 slds-text-align_center', {
                        'day-of-slot__grey': weekSummary.slot.totalDriveProductivity > 0
                    });
                    weekSummary.slot.highProductivityClass = classNames('day-of-slot slds-col slds-size_1-of-2 slds-text-align_center', {
                        'day-of-slot__green': weekSummary.slot.totalHighProductivity > 0
                    });
                    weekSummary.slot.midProductivityClass = classNames('day-of-slot slds-col slds-size_1-of-2 slds-text-align_center', {
                        'day-of-slot__amber': weekSummary.slot.totalMidProductivity > 0
                    });
                    weekSummary.slot.lowProductivityClass = classNames('day-of-slot slds-col slds-size_1-of-2 slds-text-align_center', {
                        'day-of-slot__red': weekSummary.slot.totalLowProductivity > 0
                    });
                }
            }
            week.days.push(weekSummary);
        });

        return calendarWeeks;
    }

    buildSlot_ProductGoalCalendar = (day) => {
        day.slot = {
            totalStaffs: 0,
            totalFixedSiteStaffs: 0,
            totalMobileStaffs: 0,
            noOfStaffRequested: 0,
            noOfFixedSiteStaffRequested: 0,
            noOfMobileStaffRequested: 0,
            noOfStaffRemaining: 0,
            noOfFixedSiteStaffRemaining: 0,
            noOfMobileStaffRemaining: 0,
            totalDrives: 0,
            noOfDriveRequested: 0,
            noOfDriveRemaining: 0,
            isNoOfDriveRemainingInfinity: false,
            total2RBC: 0,
            noOf2RBCRequested: 0,
            noOf2RBCRemaining: 0,
            isNoOf2RBCRemainingInfinity: false,
            totalDOT: 0,
            noOfDOTRequested: 0,
            noOfDOTRemaining: 0,
            isNoOfDOTRemainingInfinity: false,
            totalCDL: 0,
            noOfCDLRequested: 0,
            noOfCDLRemaining: 0,
            isNoOfCDLRemainingInfinity: false,
            totalVehicles: 0,
            totalBuses: 0,
            noOfVehicleRequested: 0,
            noOfBusRequested: 0,
            noOfVehicleRemaining: 0,
            noOfBusRemaining: 0,
            totalEquipments: 0,
            noOfEquipmentRequested: 0,
            noOfEquipmentRemaining: 0,
            noOfProductGoal: 0,
            noOfProductBooked: 0,
            percentOfGoal: 0,
            decreaseIndicator: false,
            staffingConstraintId: null,
            hasActivities: false
        };

        const selectedTimeBlockIds = this.filters.collectionOperationValues.timeBlocks?.map(item => item.value);

        if (this.assetMapByDateAndType[day.dateIso]?.["Equipment"]) {
            let equipment = this.assetMapByDateAndType[day.dateIso]["Equipment"];
            let effectiveEquipment = (equipment || []).filter(item => {
                const isDateValid = isNullOrEmpty(item.effectiveDate) || item.effectiveDate <= day.dateIso;
                if(!isDateValid) return false;

                const isDedicatedToFixedSite = !!item.dedicatedToSiteId;
                const driveOperationTypes = this.filters.driveOperationTypes || [];
                if((driveOperationTypes.includes(DRIVE_OPERATION_TYPE.MOBILE) || driveOperationTypes.includes(DRIVE_OPERATION_TYPE.NIFS)) 
                    && driveOperationTypes.includes(DRIVE_OPERATION_TYPE.FIXED_SITE)) {
                    return true;
                } else if(driveOperationTypes.includes(DRIVE_OPERATION_TYPE.MOBILE) || driveOperationTypes.includes(DRIVE_OPERATION_TYPE.NIFS)) {
                    return !isDedicatedToFixedSite;
                } else if(driveOperationTypes.includes(DRIVE_OPERATION_TYPE.FIXED_SITE)) {
                    return isDedicatedToFixedSite;
                }

                return true;
            });
            day.slot.totalEquipments = (effectiveEquipment || []).length;
        }
        if (this.assetMapByDateAndType[day.dateIso]?.["Vehicle"]) {
            let vehicles = this.assetMapByDateAndType[day.dateIso]["Vehicle"];
            let effectiveVehicles = (vehicles || []).filter(item => {
                const isDateValid = isNullOrEmpty(item.effectiveDate) || item.effectiveDate <= day.dateIso;
                if(!isDateValid) return false;

                return true;
            });
            effectiveVehicles.forEach(vehicle => {
                if(vehicle.category === 'Bus') {
                    day.slot.totalBuses += 1;
                } else {
                    day.slot.totalVehicles += 1;
                }
            })
        }

        this.staffingConstraintsMapByDate?.[day.dateIso]?.forEach((constraint) => {
            const isValid = (!selectedTimeBlockIds?.length && isNullOrEmpty(constraint.timeBlockId))
                            || (selectedTimeBlockIds?.length && selectedTimeBlockIds.includes(constraint.timeBlockId))
            if (isValid) {
                if(constraint.driveType === DRIVE_TYPE.FIXED_SITE) {
                    day.slot.totalFixedSiteStaffs += constraint.totalStaffConstraints;
                } else if(constraint.driveType === DRIVE_TYPE.MOBILE) {
                    day.slot.totalMobileStaffs += constraint.totalStaffConstraints;
                }
                day.slot.totalStaffs += constraint.totalStaffConstraints;
                day.slot.decreaseIndicator = constraint.decreaseIndicator;
                day.slot.staffingConstraintId = constraint.id;
            }
        });

        this.drivesMapByDate?.[day.dateIso]?.forEach((drive) => {
            const isFixedSiteDrive = drive.driveOperationType === DRIVE_OPERATION_TYPE.FIXED_SITE;

            if (!isFixedSiteDrive) {
                if(selectedTimeBlockIds?.length) {
                    drive.driveShifts?.forEach(driveShift => {
                        if (selectedTimeBlockIds.includes(driveShift.timeBlockId)) {
                            day.slot.noOfDriveRequested += 1;
                            day.slot.noOf2RBCRequested += drive.totalEquipmentRequested || 0;
                            day.slot.noOfDOTRequested += drive.noOfAllocatedDOTVehicles || 0;
                            day.slot.noOfCDLRequested += drive.noOfAllocatedCDLVehicles || 0;
                        }
                    })
                } else {
                    day.slot.noOfDriveRequested += 1;
                    day.slot.noOf2RBCRequested += drive.totalEquipmentRequested || 0;
                    day.slot.noOfDOTRequested += drive.noOfAllocatedDOTVehicles || 0;
                    day.slot.noOfCDLRequested += drive.noOfAllocatedCDLVehicles || 0;
                }
            } else {
                day.slot.noOfDriveRequested += 1;
            }
           
            if (drive.totalStaffRequested) {
                let totalStaffRequested = drive.totalStaffRequested;
                if (!isFixedSiteDrive && selectedTimeBlockIds?.length) {
                    totalStaffRequested = 0;
                    drive.driveShifts?.forEach(driveShift => {
                        if (selectedTimeBlockIds.includes(driveShift.timeBlockId)) {
                            totalStaffRequested += driveShift.staffSetup
                        }
                    })
                }

                if(isFixedSiteDrive) {
                    day.slot.noOfFixedSiteStaffRequested += totalStaffRequested;
                } else {
                    day.slot.noOfMobileStaffRequested += totalStaffRequested;
                }
                day.slot.noOfStaffRequested += totalStaffRequested;
            }

            let isVehiclesIncluded = true;
            if (selectedTimeBlockIds?.length) {
                isVehiclesIncluded = !!drive.driveShifts?.find(driveShift => selectedTimeBlockIds.includes(driveShift.timeBlockId))
            }
            if (isVehiclesIncluded) {
                const vehiclesAllocated = Math.max(drive.totalVehicleRequested || 0, drive.vehiclesAllocated || 0);
                if (vehiclesAllocated) {
                    day.slot.noOfVehicleRequested += (vehiclesAllocated - (drive.noOfAllocatedBuses || 0));
                }
                if (drive.noOfAllocatedBuses) {
                    day.slot.noOfBusRequested += drive.noOfAllocatedBuses;
                }
            }

            const equipmentAllocated = Math.max(drive.equipmentAllocated || 0, drive.totalEquipmentRequested || 0);
            if (equipmentAllocated) {
                day.slot.noOfEquipmentRequested += equipmentAllocated;
            }
            if (drive.x2rbcProjectedProcedures || drive.wbProjectedProcedures) {
                let x2rbcProjectedProcedures = drive.x2rbcProjectedProcedures || 0;
                let wbProjectedProcedures = drive.wbProjectedProcedures || 0;

                if (!isFixedSiteDrive && selectedTimeBlockIds?.length) {
                    x2rbcProjectedProcedures = 0;
                    wbProjectedProcedures = 0;
                    drive.driveShifts?.forEach(driveShift => {
                        if (selectedTimeBlockIds.includes(driveShift.timeBlockId)) {
                            x2rbcProjectedProcedures += driveShift.x2rbcProjectedProcedures || 0;
                            wbProjectedProcedures += driveShift.wbProjectedProcedures || 0;
                        }
                    })
                }

                day.slot.noOfProductBooked += (x2rbcProjectedProcedures * 2 + wbProjectedProcedures);
            }
        });

        this.activitiesMapByDate?.[day.dateIso]?.forEach((activity) => {
            day.slot.hasActivities = true;

            if (activity.reduceFromStaffingConstraint) {
                if (!selectedTimeBlockIds?.length || selectedTimeBlockIds.includes(activity.timeBlockId)) {
                    day.slot.noOfStaffRequested += (activity.quantity || 0);
                    day.slot.noOfFixedSiteStaffRequested += (activity.fixedSiteStaffQuantity || 0);
                    day.slot.noOfMobileStaffRequested += (activity.mobileStaffQuantity || 0);

                    let noOfAllocatedBuses = 0;
                    let noOfAllocatedEquipments = 0;
                    let vehiclesAllocated = 0;
                    activity.activityResources?.forEach(activityResource => {
                        const resource = activityResource.resource;
                        if (resource.resourceType !== RESOURCE_TYPE.ASSET) return;

                        if (resource.assetType === ASSET_TYPE.VEHICLE) {
                            if (resource.category === 'Bus') {
                                noOfAllocatedBuses++;
                            }
                            vehiclesAllocated++;
                        }

                        if (resource.assetType === ASSET_TYPE.EQUIPMENT) {
                            noOfAllocatedEquipments++;
                        }
                    });

                    day.slot.noOfEquipmentRequested += noOfAllocatedEquipments;
                    day.slot.noOfVehicleRequested += (vehiclesAllocated - (noOfAllocatedBuses || 0));
                    day.slot.noOfBusRequested += noOfAllocatedBuses;
                }
            }
        });

        this.productGoalsByDate?.[day.dateIso]?.forEach((goal) => {
            day.slot.noOfProductGoal += (goal.totalProducts || 0);
        });

        const collectionOpIds = this.collectionOperations.map(item => item.id);
        day.slot.totalDrives = this.planDriveHelper.findDriveLimitByDay({
            collectionOperationIds: collectionOpIds,
            driveDate: day.dateIso,
            timeBlockIds: selectedTimeBlockIds
        }, this.driveLimits, OPERATION_DRIVE_LIMIT_TYPE.DRIVE_LIMIT);
        day.slot.total2RBC = this.planDriveHelper.findDriveLimitByDay({
            collectionOperationIds: collectionOpIds,
            driveDate: day.dateIso,
            timeBlockIds: selectedTimeBlockIds
        }, this.driveLimits, OPERATION_DRIVE_LIMIT_TYPE.x2RBC_LIMIT);
        day.slot.totalDOT = this.planDriveHelper.findDriveLimitByDay({
            collectionOperationIds: collectionOpIds,
            driveDate: day.dateIso,
            timeBlockIds: selectedTimeBlockIds
        }, this.driveLimits, OPERATION_DRIVE_LIMIT_TYPE.DOT_LIMIT);
        day.slot.totalCDL = this.planDriveHelper.findDriveLimitByDay({
            collectionOperationIds: collectionOpIds,
            driveDate: day.dateIso,
            timeBlockIds: selectedTimeBlockIds
        }, this.driveLimits, OPERATION_DRIVE_LIMIT_TYPE.CDL_LIMIT);
        day.slot.noOfStaffRemaining = day.slot.totalStaffs - day.slot.noOfStaffRequested;
        day.slot.noOfFixedSiteStaffRemaining = day.slot.totalFixedSiteStaffs - day.slot.noOfFixedSiteStaffRequested;
        day.slot.noOfMobileStaffRemaining = day.slot.totalMobileStaffs - day.slot.noOfMobileStaffRequested;
        day.slot.noOfEquipmentRemaining = day.slot.totalEquipments - day.slot.noOfEquipmentRequested;
        day.slot.noOfVehicleRemaining = day.slot.totalVehicles - day.slot.noOfVehicleRequested;
        day.slot.noOfBusRemaining = day.slot.totalBuses - day.slot.noOfBusRequested;
        day.slot.noOfDriveRemaining = !isNullOrEmpty(day.slot.totalDrives) ? (day.slot.totalDrives - day.slot.noOfDriveRequested) : '∞';
        day.slot.isNoOfDriveRemainingInfinity = day.slot.noOfDriveRemaining === '∞';
        day.slot.noOf2RBCRemaining = !isNullOrEmpty(day.slot.total2RBC) ? (day.slot.total2RBC - day.slot.noOf2RBCRequested) : '∞';
        day.slot.isNoOf2RBCRemainingInfinity = day.slot.noOf2RBCRemaining === '∞';
        day.slot.noOfDOTRemaining = !isNullOrEmpty(day.slot.totalDOT) ? (day.slot.totalDOT - day.slot.noOfDOTRequested) : '∞';
        day.slot.isNoOfDOTRemainingInfinity = day.slot.noOfDOTRemaining === '∞';
        day.slot.noOfCDLRemaining = !isNullOrEmpty(day.slot.totalCDL) ? (day.slot.totalCDL - day.slot.noOfCDLRequested) : '∞';
        day.slot.isNoOfCDLRemainingInfinity = day.slot.noOfCDLRemaining === '∞';

        if (day.slot.noOfProductGoal) {
            day.slot.percentOfGoal = Number(day.slot.noOfProductBooked / day.slot.noOfProductGoal).toFixed(2);
        }

        day.slot.productGoalIndicatorClass = classNames('day-of-slot slds-col slds-size_1-of-3 slds-text-align_center', {
            'day-of-slot__green': day.slot.percentOfGoal >= 1,
            'day-of-slot__red': day.slot.percentOfGoal < 1,
        });
        day.slot.staffIndicatorClass = classNames('day-of-slot slds-col slds-size_1-of-3 slds-text-align_center', {
            'day-of-slot__green': day.slot.noOfStaffRemaining > 0,
            'day-of-slot__red': day.slot.noOfStaffRemaining <= 0,
        });

        day.slot.driveIndicatorClass = classNames('day-of-slot slds-col slds-size_1-of-3 slds-text-align_center slds-text-body_small', {
            'day-of-slot__green': day.slot.noOfDriveRemaining > 0 || day.slot.isNoOfDriveRemainingInfinity,
            'day-of-slot__red': day.slot.noOfDriveRemaining <= 0 && !day.slot.isNoOfDriveRemainingInfinity,
        });

        day.slot.x2RBCIndicatorClass = classNames('day-of-slot slds-col slds-size_1-of-3 slds-text-align_center slds-text-body_small', {
            'day-of-slot__green': day.slot.noOf2RBCRemaining > 0 || day.slot.isNoOf2RBCRemainingInfinity,
            'day-of-slot__red': day.slot.noOf2RBCRemaining <= 0 && !day.slot.isNoOf2RBCRemainingInfinity,
        });

        day.slot.DOTIndicatorClass = classNames('day-of-slot slds-col slds-size_1-of-3 slds-text-align_center slds-text-body_small', {
            'day-of-slot__green': day.slot.noOfDOTRemaining > 0 || day.slot.isNoOfDOTRemainingInfinity,
            'day-of-slot__red': day.slot.noOfDOTRemaining <= 0 && !day.slot.isNoOfDOTRemainingInfinity,
        });

        day.slot.CDLIndicatorClass = classNames('day-of-slot slds-col slds-size_1-of-3 slds-text-align_center slds-text-body_small', {
            'day-of-slot__green': day.slot.noOfCDLRemaining > 0 || day.slot.isNoOfCDLRemainingInfinity,
            'day-of-slot__red': day.slot.noOfCDLRemaining <= 0 && !day.slot.isNoOfCDLRemainingInfinity,
        });

        day.slot.vehicleIndicatorClass = classNames('day-of-slot slds-col slds-size_1-of-3 slds-text-align_center', {
            'day-of-slot__green': day.slot.noOfVehicleRemaining > 0,
            'day-of-slot__red': day.slot.noOfVehicleRemaining <= 0,
        });

        day.slot.busIndicatorClass = classNames('day-of-slot slds-col slds-size_1-of-3 slds-text-align_center', {
            'day-of-slot__green': day.slot.noOfBusRemaining > 0,
            'day-of-slot__red': day.slot.noOfBusRemaining <= 0,
        });

        day.slot.equipmentIndicatorClass = classNames('day-of-slot slds-col slds-size_1-of-3 slds-text-align_center', {
            'day-of-slot__green': day.slot.noOfEquipmentRemaining > 0,
            'day-of-slot__red': day.slot.noOfEquipmentRemaining <= 0,
        });
    }

    buildSlot_ProductivityCalendar = (day) => {
        day.slot = {
            totalDrives: 0,
            totalDriveProductivity: 0,
            averageProductivity: 0,
            noOfHighProductivityDrives: 0,
            totalHighProductivity: 0,
            averageHighProductivityDrives: 0,
            noOfMidProductivityDrives: 0,
            totalMidProductivity: 0,
            averageMidProductivityDrives: 0,
            noOfLowProductivityDrives: 0,
            totalLowProductivity: 0,
            averageLowProductivityDrives: 0
        };
        
        let drives = this.drivesMapByDate[day.dateIso];
        if (drives && drives.length) {
            day.slot.totalDrives = drives.length;
            drives.forEach((drive) => {
                let driveProductivityPlanned = Number(drive.driveProductivityPlanned);
                day.slot.totalDriveProductivity += driveProductivityPlanned;
                let territoryCollectionOperation = ((this.filters.collectionOperationValues || {}).territoryCollectionOperations || []).find(item => item.territoryId == drive.territoryId);

                const territory = this.territoriesMapById[territoryCollectionOperation.territoryId];

                if(territory) {
                    if (driveProductivityPlanned < territory.midDriveProductivityThreshold) {
                        day.slot.noOfLowProductivityDrives++;
                        day.slot.totalLowProductivity += driveProductivityPlanned;
                    }
                    else if (driveProductivityPlanned < territory.highDriveProductivityThreshold) {
                        day.slot.noOfMidProductivityDrives++;
                        day.slot.totalMidProductivity += driveProductivityPlanned;
                    }
                    else {
                        day.slot.noOfHighProductivityDrives++;
                        day.slot.totalHighProductivity += driveProductivityPlanned;
                    }
                }
            });
            day.slot.averageProductivity = this.standardlizeNumber(day.slot.totalDriveProductivity / day.slot.totalDrives);
            if (day.slot.totalHighProductivity) {
                day.slot.averageHighProductivityDrives = this.standardlizeNumber(day.slot.totalHighProductivity / day.slot.noOfHighProductivityDrives);
            }
            if (day.slot.totalMidProductivity) {
                day.slot.averageMidProductivityDrives = this.standardlizeNumber(day.slot.totalMidProductivity / day.slot.noOfMidProductivityDrives);
            }
            if (day.slot.totalLowProductivity) {
                day.slot.averageLowProductivityDrives = this.standardlizeNumber(day.slot.totalLowProductivity / day.slot.noOfLowProductivityDrives);
            }
        }
        day.slot.summaryClass = classNames('day-of-slot slds-col slds-size_1-of-2 slds-text-align_center', {
            'day-of-slot__grey': day.slot.totalDriveProductivity > 0
        });
        day.slot.highProductivityClass = classNames('day-of-slot slds-col slds-size_1-of-2 slds-text-align_center', {
            'day-of-slot__green': day.slot.totalHighProductivity > 0
        });
        day.slot.midProductivityClass = classNames('day-of-slot slds-col slds-size_1-of-2 slds-text-align_center', {
            'day-of-slot__amber': day.slot.totalMidProductivity > 0
        });
        day.slot.lowProductivityClass = classNames('day-of-slot slds-col slds-size_1-of-2 slds-text-align_center', {
            'day-of-slot__red': day.slot.totalLowProductivity > 0
        });
    }

    rebuildProductGoalCalendar = () => {
        const selectedMonth = this.filters.selectedMonth || DateTime.local().toISODate()
        let { startDate, endDate } = this.calendarHelper.getDateRange(selectedMonth);
        startDate = this.dateUtils.startOf(startDate, 'week');
        endDate = this.dateUtils.endOf(endDate, 'week');
        const territoryKeys = this.territoryKeys;
        const collectionOpIds = this.collectionOperations.map(item => item.id);
        if (!territoryKeys || !territoryKeys.length || !selectedMonth) {
            this.assetMapByDateAndType = {};
            this.drivesMapByDate = {};
            this.activitiesMapByDate = {};
            this.staffingConstraintsMapByDate = {};
            this.productGoalsByDate = {};
            return;
        }

        this.showSpinner = true;
        Promise.resolve()
            .then(() => {
                let staffingConstraintQuery = new staffingConstraintQueryModel();
                staffingConstraintQuery.startDate = startDate;
                staffingConstraintQuery.endDate = endDate;
                staffingConstraintQuery.collectionOpIds = collectionOpIds;
                staffingConstraintQuery.driveTypes = this.filters.driveOperationTypes;

                let productGoalQuery = new productGoalQueryModel();
                productGoalQuery.startDate = startDate;
                productGoalQuery.endDate = endDate;
                productGoalQuery.collectionOperationIds = collectionOpIds;
                productGoalQuery.driveTypes = this.filters.driveOperationTypes;
                productGoalQuery.procedureTypes = this.filters.procedureTypes;
                
                let driveQuery = new driveQueryModel();
                driveQuery.territoryKeys = territoryKeys;
                driveQuery.startDate = startDate;
                driveQuery.endDate = endDate;
                driveQuery.driveOperationTypes = this.filters.driveOperationTypes;
                driveQuery.statuses = this.filters.driveStatuses;
                driveQuery.stages = this.filters.stages;
                driveQuery.accountTypes = this.filters.accountTypes;
                driveQuery.accountIndustryCodes = this.filters.accountIndustryCodes;
                driveQuery.procedureTypes = this.filters.procedureTypes;
                // driveQuery.recruitedBys = this.filters.recruitedBys;
                driveQuery.markets = (this.filters.markets || []).map(market => {
                    return market.id;
                });
                driveQuery.accountManagerPortfolioIds = (this.filters.accountManagerPortfolios || []).map(accountManagerPortfolio => {
                    return accountManagerPortfolio.id;
                });
                driveQuery.districtManagerPortfolioIds = (this.filters.districtManagerPortfolios || []).map(districtManagerPortfolio => {
                    return districtManagerPortfolio.id;
                })
                driveQuery.daysOfWeek = this.filters.daysOfWeek;
                if (this.isTimeBlockApplied) {
                    driveQuery.subQueryIndicator = sObjectType.DRIVE_SHIFT;
                }

                let activityQuery = new activityQueryModel();
                //activityQuery.territoryKeys = territoryKeys;
                activityQuery.startDate = startDate;
                activityQuery.endDate = endDate;
                activityQuery.isGroupActivity = true;
                activityQuery.isShowOnCalendarOrReduceFromStaffingConstraints = true;
                activityQuery.subQueryIndicator = sObjectType.ACTIVITY_RESOURCE | sObjectType.ACTIVITY_COLLECTION_OPERATION;

                const driveLimitQuery = new operationDriveLimitQueryModel();
                driveLimitQuery.effectiveStartDate = startDate;
                driveLimitQuery.effectiveEndDate = endDate;
                driveLimitQuery.collectionOperationIds = collectionOpIds;

                let staffingConstraintSvc = new staffingConstraintService();
                let productGoalSvc = new productGoalService();
                let driveSvc = new driveService();
                let activitySvc = new activityService();
                let holidaySvc = new holidayService();
                let calendarMessageSvc = new calendarMessageService();
                const driveLimitSvc = new operationDriveLimitService();

                return Promise.all([
                    staffingConstraintSvc.query(staffingConstraintQuery),
                    productGoalSvc.query(productGoalQuery),
                    driveSvc.query(driveQuery),
                    driveLimitSvc.query(driveLimitQuery),
                    activitySvc.query(activityQuery),
                    holidaySvc.getHolidays(collectionOpIds, startDate, endDate),
                    calendarMessageSvc.getCalendarMessages(collectionOpIds, startDate, endDate)
                ])
            })
            .then(([staffingConstraintResult, productGoalResult, driveResult, driveLimitResult, activityResult, holidayResult, calendarMessageResult]) => {
                this.staffingConstraintsMapByDate = groupBy(staffingConstraintResult, 'dateOfConstraint');
                this.productGoalsByDate = groupBy(productGoalResult, 'dateOfGoal');
                this.drivesMapByDate = groupBy(driveResult, 'driveDate');
                let activities = activityResult.filter((activity) => {
                    return (
                        territoryKeys.includes(activity.territoryKey) ||
                        (activity.activityCollectionOperations || []).find((activityCollectionOperation => territoryKeys.includes(activityCollectionOperation.territoryKey)))
                    );
                });
                activities.forEach((activity) => {
                    let activityStart = DateTime.fromISO(activity.start, { zone: activity.timezoneSidId });
                    activity.activityDate = activityStart.toISODate();
                });
                this.activitiesMapByDate = groupBy(activities, 'activityDate');
                this.holidays = holidayResult;
                this.calendarMessages = calendarMessageResult;
                this.driveLimits = driveLimitResult;

                //get assets
                const diff = this.dateUtils.diffDays(startDate, endDate);
                const jobs = [];
                for (let i = 0; i <= diff; i++) {
                    let currentDay = DateTime.fromFormat(startDate, 'yyyy-MM-dd', {
                        zone: TIME_ZONE
                    }).plus({
                        days: i
                    });

                    const start = currentDay.toUTC().toISO();
                    const finish = currentDay.plus({
                        hours: 23,
                        minutes: 59
                    }).toUTC().toISO();

                    jobs.push({
                        id: uniqueId(`temp_job_`),
                        start: start,
                        finish: finish,
                        driveDate: currentDay.toISODate(),
                        collectionOperationIds: collectionOpIds
                    })
                }

                this.availator = slwcAvailator.getInstance({
                    mapApis: window.google ? window.google.maps : null,
                    considerDateOnly: true
                })
                return this.availator.fetchAssetsDataDriveCalendar(jobs, {
                    timezoneSidId: TIME_ZONE,
                    excludedDriveIds: uniq(driveResult.map(item => item.id)),
                    excludedActivityIds: uniq(activityResult.map(item => item.id)),
                    collectionOperationIds: this.collectionOperations.map(item => item.id)
                })
                    .then(() => {
                        return this.availator.buildScheduledAllocations({
                            ignoreDedicatedSiteRule: true
                        });
                    })
                    .then((result) => {
                        const validVehiclePossibleAllocations = (result.possibleAllocations || []).filter(posAl => {
                            const noException = (posAl.exceptionLog || []).length === 0;
                            return noException && posAl.resource.assetType === ASSET_TYPE.VEHICLE;
                        })

                        const validEquipmentPossibleAllocations = (result.possibleAllocations || []).filter(posAl => {
                            const noException = (posAl.exceptionLog || []).length === 0;
                            return noException && posAl.resource.assetType === ASSET_TYPE.EQUIPMENT;
                        })
                        const groupedVehicleByDateIso = groupBy(validVehiclePossibleAllocations, (item) => item.job.driveDate);
                        const groupedEquipmentByDateIso = groupBy(validEquipmentPossibleAllocations, (item) => item.job.driveDate);

                        const groupedByDateIsoAndType = {};
                        Object.keys(groupedVehicleByDateIso).map(dateIso => {
                            groupedByDateIsoAndType[dateIso] = {
                                [ASSET_TYPE.EQUIPMENT]: (groupedEquipmentByDateIso[dateIso] || []).map(item => item.resource),
                                [ASSET_TYPE.VEHICLE]: (groupedVehicleByDateIso[dateIso] || []).map(item => item.resource),
                            }
                        });
                        return groupedByDateIsoAndType;
                    })
            })
            .then((assetMapByDateAndType = {}) => {
                this.assetMapByDateAndType = assetMapByDateAndType;
                this.calendarWeeks = this.buildCalendarWeeks();
                this.monthSummary = this.buildMonthSummary();
            })
            .catch((error) => {
                console.log(error);
            })
            .finally(() => {
                this.showSpinner = false
            });
    }

    rebuildProductivityCalendar = () => {
        const selectedMonth = this.filters.selectedMonth || DateTime.local().toISODate()
        let { startDate, endDate } = this.calendarHelper.getDateRange(selectedMonth);
        startDate = this.dateUtils.startOf(startDate, 'week');
        endDate = this.dateUtils.endOf(endDate, 'week');
        const territoryKeys = this.territoryKeys;
        const collectionOpIds = this.collectionOperations.map(item => item.id);

        if (!territoryKeys || !territoryKeys.length || !selectedMonth) {
            this.drivesMapByDate = {};
            return;
        }

        const territoryIds = territoryKeys.map(key => key.split(':')[0]);

        this.showSpinner = true;
        Promise.resolve()
            .then(() => {
                let driveQuery = new driveQueryModel();
                driveQuery.territoryKeys = territoryKeys;
                driveQuery.startDate = startDate;
                driveQuery.endDate = endDate;
                driveQuery.eventTypes = this.filters.driveTypes;
                driveQuery.statuses = this.filters.driveStatuses;
                driveQuery.stages = this.filters.stages;
                driveQuery.accountTypes = this.filters.accountTypes;
                driveQuery.accountIndustryCodes = this.filters.accountIndustryCodes;
                // driveQuery.recruitedBys = this.filters.recruitedBys;
                driveQuery.markets = (this.filters.markets || []).map(market => {
                    return market.id;
                });
                // driveQuery.daysOfWeek = this.filters.daysOfWeek;
                
                let territoryQuery = new territoryQueryModel();
                territoryQuery.recordIds = territoryIds;

                let driveSvc = new driveService();
                let holidaySvc = new holidayService();
                let calendarMessageSvc = new calendarMessageService();
                let territorySvc = new territoryService();

                return Promise.all([
                    driveSvc.query(driveQuery),
                    holidaySvc.getHolidays(collectionOpIds, startDate, endDate),
                    calendarMessageSvc.getCalendarMessages(collectionOpIds, startDate, endDate),
                    territorySvc.query(territoryQuery)
                ])
            })
            .then(([driveResult, holidayResult, calendarMessageResult, territoryResult]) => {
                this.drivesMapByDate = groupBy(driveResult, 'driveDate');
                this.holidays = holidayResult;
                this.calendarMessages = calendarMessageResult;
                this.territoriesMapById = territoryResult.reduce((map, territory) => {
                    map[territory.id] = territory;
                    return map;
                }, {});


                this.calendarWeeks = this.buildCalendarWeeks();
                this.monthSummary = this.buildMonthSummary();
            })
            .catch((error) => {
                console.log(error);
            })
            .finally(() => {
                this.showSpinner = false
            });
    }

    handleSelectWeek(event) {
        const weekStartDate = event.currentTarget.dataset['value'];
        if (!weekStartDate) return;

        const dispatchEvent = new CustomEvent('selectweek', {
            bubbles: true,
            composed: true,
            detail: {
                weekStartDate: weekStartDate,
                filters: this.filters
            }
        });
        this.dispatchEvent(dispatchEvent);
    }

    handleSelectDate(event) {
        const selectedDate = event.currentTarget.dataset['value'];
        if (!selectedDate) return;

        const dispatchEvent = new CustomEvent('selectdate', {
            bubbles: true,
            composed: true,
            detail: {
                selectedDate: selectedDate,
                filters: this.filters
            }
        });
        this.dispatchEvent(dispatchEvent);
    }

    handleAcknowledgeDecrease(event) {
        if (this.hasAccess()) {
            event.stopPropagation();

            let staffingConstraintId = event.currentTarget.dataset['staffingConstraint'];

            this.showConfirmModal({
                title: 'Acknowledge Staffing Constraint Decrease',
                message: 'Do you want to clear staffing constraint decrease indicator?',
                onClose: (result) => {
                    this.hideConfirmModal();
                    if (result) {
                        this.doAcknowledgeDecrease(staffingConstraintId);
                    }
                },
                confirmBtnLabel: 'Yes',
                cancelBtnLabel: 'No'
            });
        }
    }

    doAcknowledgeDecrease(staffingConstraintId) {
        let model = {
            id: staffingConstraintId,
            decreaseIndicator: false
        }
        let service = new staffingConstraintService();
        this.showSpinner = true;
        return service.save(model)
            .then((result) => {
                this.dispatchEvent(new ShowToastEvent({
                    message: 'Staffing Constraint Decrease Indicator was cleared.',
                    variant: 'success',
                    mode: 'dismissable'
                }));
            })
            .then(() => {
                this.rebuildProductGoalCalendar();
            })
            .finally(() => {
                this.showSpinner = false
            });
    }

    standardlizeNumber(rawNumber) {
        if(isNullOrEmpty(rawNumber)) {
            return null;
        }

        return +Number(rawNumber).toFixed(4);
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