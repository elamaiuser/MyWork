/**
 * Lead / Account 360 View Card
 * ---------------------------------------------
 * This component renders a 360-degree summary view
 * with financials, activities, gifts, drives,
 * courses, contracts, and related accounts.
 *
 * Modal-driven architecture is used to display
 * drill-down details for each section.
 */
import { LightningElement, track, wire, api } from 'lwc';
/**
 * Apex controllers
 */
import queryDataCloud from '@salesforce/apex/SFC360_Lead360ViewController.queryDataCloud';
import queryActivityModal from '@salesforce/apex/SFC360_Lead360ViewController.queryActivityModal';
import queryRelatedAccountDetails from '@salesforce/apex/SFC360_Lead360ViewController.queryRelatedAccountDetails';

/**
 * Static resources and labels
 */
import GREEN from '@salesforce/resourceUrl/greenIcon';
import GRAY from '@salesforce/resourceUrl/grayIcon';
import SHOW_HS_DATA from '@salesforce/label/c.Show_HS_Financial_Data';

/**
 * Datatable column configurations
 * ---------------------------------------------
 * These are static and reused across modals.
 */

const hsColumns = [
    {
        label: 'Products', fieldName: 'products', type: 'text', cellAttributes: {
            class: { fieldName: 'rowStyle' }
        }
    },
    {
        label: 'Revenue', fieldName: 'revenue', type: 'currency', cellAttributes: {
            class: { fieldName: 'rowStyle' }
        }
    },
    {
        label: 'Volume', fieldName: 'volume', type: 'number', cellAttributes: {
            class: { fieldName: 'rowStyle' }
        }
    },

];

const cgtsColumns = [
    {
        label: 'Contract Stage', fieldName: 'stage', type: 'text'

    },
    {
        label: 'Total Product Count', fieldName: 'productCount', type: 'number'
    },
    {
        label: 'Total Value', fieldName: 'totalValue', type: 'currency'
    },

];

const contractDataColumns = [
    {
        label: 'Contract Number', fieldName: 'ContractNumber', type: 'text'
    },
    {
        label: 'Type', fieldName: 'Type', type: 'text'
    },
    {
        label: 'Status', fieldName: 'Status', type: 'text'
    },
    {
        label: 'Is Active', fieldName: 'IsActive', type: 'text'
    },
    {
        label: 'Start Date', fieldName: 'StartDate', type: 'text'
    },
    {
        label: 'End Date', fieldName: 'EndDate', type: 'text'
    },
    {
        label: 'Total Amount', fieldName: 'TotalAmount', type: 'currency'
    },

];

const accDetailsDataColumns = [
    {
        label: 'Org Name', fieldName: 'orgName', type: 'text', initialWidth: 150, hideDefaultActions: true
    },
    {
        label: 'Account Name', fieldName: 'accountName', type: 'text', initialWidth: 200, hideDefaultActions: true
    },
    {
        label: 'Address', fieldName: 'accAddress', type: 'text', initialWidth: 250, hideDefaultActions: true
    },
    {
        label: 'City', fieldName: 'accCity', type: 'text', initialWidth: 120, hideDefaultActions: true
    },
    {
        label: 'State', fieldName: 'accState', type: 'text', initialWidth: 80, hideDefaultActions: true
    },
    {
        label: 'Zip Code', fieldName: 'accZipcode', type: 'text', initialWidth: 100, hideDefaultActions: true
    },       
    {
        label: 'Phone Number', fieldName: 'accPhone', type: 'text', initialWidth: 120, hideDefaultActions: true
    },
    {
        label: 'Account Manager', fieldName: 'accManager', type: 'text', initialWidth: 200, hideDefaultActions: true
    },
    {
        label: 'Account Id', fieldName: 'accRecId', type: 'text', initialWidth: 150, hideDefaultActions: true
    }
];

const giftDetailsDataColumns = [
    {
        label: 'Account Id', fieldName: 'accRecId', type: 'text'
    },
    {
        label: 'Account Name', fieldName: 'accountName', type: 'text'
    },
    {
        label: 'Gift Amount', fieldName: 'giftAmount', type: 'currency'
    }
];

const driveDetailsDataColumns = [
    {
        label: 'Drive Id', fieldName: 'driveRecId', type: 'text'
    },
    {
        label: 'Drive Name', fieldName: 'driveName', type: 'text'
    },
    {
        label: 'Drive Date', fieldName: 'driveDate', type: 'text'
    },
    {
        label: 'Org Name', fieldName: 'orgName', type: 'text'
    },
    {
        label: 'Drive Status', fieldName: 'driveStatus', type: 'text'
    }
];

const courseDetailsDataColumns = [
    {
        label: 'Course Id', fieldName: 'courseId', type: 'text'
    },
    {
        label: 'Course Name', fieldName: 'trainingClass', type: 'text'
    },
    {
        label: 'Account Name', fieldName: 'accountName', type: 'text'
    }
];

export default class SfC360_Lead360ViewCard extends LightningElement {

    @track hsData = [];
    @track CGTSRevenue = [];
       /**
     * Record context provided by Lightning framework
     */
    @api objectApiName;
    @api recordId;

    /**
     * Core data containers
     */
    @track accAmDetails = {};
    @track HSRevenueData = [];
    @track CGTSRevenueData = [];
    @track groupedActivities = [];
    @track openTasks = {};

    /**
     * UI state variables
     */
    isLoading = false;
    isModalOpen = false;
    @track isModalLoading = false;
    modalType = null;
    modalTitle = '';

    /**
     * Header values
     */
    header = '';
    headerIcon = '';

    /**
     * KPI values
     */
    recordsCompleted = 0;
    plannedDrives = 0;
    plannedCourses = 0;
    coursesCompleted = 0;
    numberOfAccounts = 0;

    /**
     * Gift & contract summary values
     */
    frGiftCount = '';
    frTotalGiftAmount = '';
    frTotalGiftAmountVal = '';
    lifetimeContractCount = '';
    lifetimeContractAmount = '';

    /**
     * Account identifiers
     */
    unifiedAccId;
    hsAccId;
    frActivityAccId;
    hsActivityAccId;
    tsActivityAccId;

    /**
     * Activity counters
     */
    openActivityFR = 0;
    totalActivityFR = 0;
    openActivityHS = 0;
    totalActivityHS = 0;
    openActivityTS = 0;
    totalActivityTS = 0;

    /**
     * Modal data containers
     */
    accountDetailsData = [];
    giftDetailsData = [];
    driveDetailsData = [];
    courseDetailsData = [];
    contractData = [];

    /**
     * Datatable column references
     */
    hsColumns = hsColumns;
    cgtsColumns = cgtsColumns;
    contractDataColumns = contractDataColumns;
    accDetailsDataColumns = accDetailsDataColumns;
    giftDetailsDataColumns = giftDetailsDataColumns;
    driveDetailsDataColumns = driveDetailsDataColumns;
    courseDetailsDataColumns = courseDetailsDataColumns;

    /**
     * Static resources
     */
    greenIcon = GREEN;
    grayIcon = GRAY;

    /**
     * Custom label driven toggle
     */
    showHSData = SHOW_HS_DATA;

    //getters : 
    get isAccountModal() {
        return this.modalType === 'ACCOUNT';
    }

    get isGiftModal() {
        return this.modalType === 'GIFT';
    }

    get isDriveModal() {
        return this.modalType === 'DRIVE';
    }

    get isCourseModal() {
        return this.modalType === 'COURSE';
    }
    get isActivityModal() {
        return this.modalType === 'ACTIVITY';
    }
    get isContractModal() {
        return this.modalType === 'CONTRACT';
    }
    get hasDriveDetails() {
        return Array.isArray(this.driveDetailsData) && this.driveDetailsData.length > 0;
    }
    get hasGiftDetails() {
        return Array.isArray(this.giftDetailsData) && this.giftDetailsData.length > 0;
    }
    get hasAccountDetails() {
        return Array.isArray(this.accountDetailsData) && this.accountDetailsData.length > 0;
    }
    get hasContractDetails() {
        return Array.isArray(this.contractData) && this.contractData.length > 0;
    }
    get showFinancialData() {
        return this.showHSData.toLowerCase() === 'true';
    }
    get wiredParams() {
        return {
            dataSourceObjectId: this.objectApiName,
            sourceRecId: this.recordId,
        };
    }
    get accAmArray() {
        return Object.entries(this.accAmDetails).map(([orgName, value]) => {
            const hasAccounts = value && value.length > 0;
            const accounts = (value || []).map(v => ({
                name: v.name,
                email: v.email,
                mailto: v.email ? `mailto:${v.email}` : null
            }));

            return {
                orgName,
                accounts,
                statusIcon: hasAccounts ? this.greenIcon : this.grayIcon
            };
        });
    }

    get fetchGroupedActivities() {
        if (!this.groupedActivities || !this.groupedActivities.length) {
            return [];
        }

        const upcomingAndOverdue = [];

        const buildActivity = (activity) => {
            const baseClass = 'slds-timeline__item_expandable';

            const typeClass =
                activity.type === 'Email'
                    ? 'slds-timeline__item_email'
                    : activity.type === 'Task'
                        ? 'slds-timeline__item_task'
                        : activity.type === 'Call'
                            ? 'slds-timeline__item_call'
                            : '';

            const isOpen = !!this.openTasks[activity.taskId];

            return {
                ...activity,
                toggleIcon: isOpen ? 'utility:chevrondown' : 'utility:chevronright',
                typeIcon: this.getIconName(activity.type),
                isOpen,
                isTask: activity.type === 'Task',
                isEmail: activity.type === 'Email',
                isCall: activity.type === 'Call',
                isClosed: activity.isClosed === 'true',
                timelineItemClass: `${baseClass} ${typeClass} ${isOpen ? 'slds-is-open' : ''}`
            };
        };

        const transformedGroups = this.groupedActivities.map(group => {
            const values = [];

            group.activities.forEach(activity => {
                const isUpcoming =
                    activity.isClosed === 'false' && activity.isUpcoming;

                if (isUpcoming) {
                    upcomingAndOverdue.push(buildActivity(activity));
                } else {
                    values.push(buildActivity(activity));
                }
            });

            return {
                key: group.groupLabel,
                values,
                isUpcomingGroup: false
            };
        });

        // Remove empty groups
        const filteredGroups = transformedGroups.filter(
            group => group.values.length > 0
        );

        // Add Upcoming & Overdue section at top (only if data exists)
        if (upcomingAndOverdue.length) {
            filteredGroups.unshift({
                key: 'Upcoming & Overdue',
                values: upcomingAndOverdue,
                isUpcomingGroup: true
            });
        }

        return filteredGroups;
    }
    get getObjectApiName() {
        this.objectApiName == 'Account' ? this.header = 'Account 360' : this.header = 'Lead 360';
        this.objectApiName == 'Account' ? this.headerIcon = 'standard:account' : this.headerIcon = 'standard:lead';
        return this.objectApiName;
    }   

    //------------------------------------------------------------------------------------------------------------------------------
    //Helper methods :

    /**
     * Modal helpers
     */
    openModal(type, title) {
        this.modalType = type;
        this.modalTitle = title;
        this.isModalOpen = true;
        this.isModalLoading = true;
    }
    closeModal() {
        this.isModalOpen = false;
        this.isModalLoading = false;
        this.modalType = null;
    }

    /**
     * Opens Activity modal and fetches activities
     * ---------------------------------------------
     * Triggered when user clicks on Activity count
     */
    handleModalClickActivity(event) {
        console.log('----------inside handleModalClickActivity');
        event.preventDefault();

        const accId = event.currentTarget.dataset.accid; // HS / FR / TS
        if (!accId) {
            return;
        }

        this.openModal('ACTIVITY', 'Activities');
        this.fetchActivity(accId);
    }

    /**
     * Opens Account Details modal
     * ---------------------------------------------
     * Fetches all related accounts using unified account id
     */
    handleModalClickAccountDetails(event) {
        event.preventDefault();
        this.openModal('ACCOUNT', 'Account Details');
        this.fetchAccountdetails(this.unifiedAccId);
    }

    /**
     * Opens Gift Details modal
     * ---------------------------------------------
     * Handles both gift count and total gift amount clicks
     */
    handleModalClickGiftDetails(event) {
        event.preventDefault();

        const giftType = event.currentTarget.dataset.type;
        const valueClicked =
            giftType === 'giftCount'
                ? Number(this.frGiftCount)
                : Number(this.frTotalGiftAmountVal);

        this.openModal('GIFT', 'Gift Details');

        if (valueClicked === 0) {
            this.giftDetailsData = [];
            this.isModalLoading = false;
            return;
        }

        this.fetchGiftdetails(this.unifiedAccId);
    }

    /**
     * Opens Drive Details modal
     * ---------------------------------------------
     * Handles both Completed and Planned drives
     * Skips fetch when clicked count is zero
     */
    handleModalClickDriveDetails(event) {
        event.preventDefault();

        const driveType = event.currentTarget.dataset.type;
        const valueClicked =
            driveType === 'Completed'
                ? Number(this.recordsCompleted)
                : Number(this.plannedDrives);

        this.openModal('DRIVE', 'Drive Details');

        if (valueClicked === 0) {
            this.driveDetailsData = [];
            this.isModalLoading = false;
            return;
        }

        this.fetchDrivedetails(this.unifiedAccId, driveType);
    }
    /**
     * Opens Course Details modal
     * ---------------------------------------------
     * Handles both Completed and Planned courses
     */
    handleModalClickCourseDetails(event) {
        event.preventDefault();

        const courseType = event.currentTarget.dataset.type;
        const valueClicked =
            courseType === 'Completed'
                ? Number(this.coursesCompleted)
                : Number(this.plannedCourses);

        this.openModal('COURSE', 'Course Details');

        if (valueClicked === 0) {
            this.courseDetailsData = [];
            this.isModalLoading = false;
            return;
        }

        this.fetchCoursedetails(this.unifiedAccId, courseType);
    }
    
    /**
     * Expands / collapses activity task group
     * ---------------------------------------------
     * Maintains open state per task id
     */
    toggleButton(event) {
        const taskId = event.currentTarget.dataset.taskid;
        if (!taskId) {
            return;
        }

        this.openTasks = {
            ...this.openTasks,
            [taskId]: !this.openTasks[taskId]
        };
    }

    /**
     * Returns chevron icon based on expanded state
     */
    getToggleIcon(taskId) {
        return this.openTasks[taskId] ? 'utility:chevrondown' : 'utility:chevronright';
    }

    /**
     * Returns icon based on activity type
     */
    getIconName(type) {
        switch ((type || '').toLowerCase()) {
            case 'email':
                return 'standard:email';
            case 'call':
                return 'action:log_a_call';
            default:
                return 'standard:task';
        }
    }
    /**
     * Static icons used across UI
     */
    greenIcon = GREEN;
    grayIcon = GRAY;

    connectedCallback() {
        this.loadData();
    }
            
    /**
     * Fetches related account details
     */
    fetchAccountdetails(recId) {
        const unifiedAccId = recId;
        queryRelatedAccountDetails({ unifiedAccId })
            .then((data) => {
                console.log(data);
                if (data) {
                    this.accountDetailsData = data.accountData || [];
                }
            }
            ).catch((error) => {
                this.isModalOpen = false;
                this.error = error;
                console.error('Error fetching data:', error);
            })
            .finally(() => {
                //this.isCustomModalLoading = false;
                this.isModalLoading = false;
            });
    }
    /**
     * Fetches activity data and groups it
     * ---------------------------------------------
     * Clears previous data before loading fresh results
     */
    fetchActivity(recId) {
        this.groupedActivities = [];

        queryActivityModal({ accId: recId })
            .then((data) => {
                console.log(data.activityData);
                if (data && data.activityData) {
                    this.groupedActivities = data.activityData;
                }
            })
            .catch((error) => {
                this.isModalOpen = false;
                this.error = error;
                console.error('Error fetching activities:', error);
            })
            .finally(() => {
                this.isModalLoading = false;
            });
    }
    /**
     * Main data load for the 360 card
     */
    loadData() {
        const params = this.wiredParams;
        this.isLoading = true;
        queryDataCloud({ params })
            .then((data) => {
                if (data) {
                    console.log(data);
                    this.unifiedAccId = data.unifiedId || '';
                    this.accAmDetails = data.accAmDetails || {};
                    console.log(this.accAmDetails);
                    this.recordsCompleted = isNaN(parseFloat(data.recordsCompleted).toString()) ? '0' : parseFloat(data.recordsCompleted).toString();
                    this.plannedDrives = isNaN(parseFloat(data.plannedDrives).toString()) ? '0' : parseFloat(data.plannedDrives).toString();
                    //this.unitsCollected = data.unitsCollected || 0;
                    this.plannedCourses = data.plannedCourses || 0;
                    this.numberOfAccounts = isNaN(parseFloat(data.numberOfAccounts).toString()) ? '0' : parseFloat(data.numberOfAccounts).toString();
                    this.coursesCompleted = isNaN(parseFloat(data.coursesCompleted).toString()) ? '0' : parseFloat(data.coursesCompleted).toString();
                    this.frGiftCount = isNaN(parseFloat(data.giftCount).toString()) ? '0' : parseFloat(data.giftCount).toString();
                    this.frTotalGiftAmountVal = isNaN(parseFloat(data.totalGiftAmount).toString()) ? '0.00' : parseFloat(data.totalGiftAmount).toString();
                    this.frTotalGiftAmount = this.formatCurrency(this.frTotalGiftAmountVal);
                    this.HSRevenueData = data.HSRevenueData ? Object.entries(data.HSRevenueData) : [];
                    this.CGTSRevenueData = data.CGTSRevenue || [];
                    this.lifetimeContractCount = isNaN(parseFloat(data.lifetimeContractCount).toString()) ? '0' : parseFloat(data.lifetimeContractCount).toString();
                    this.lifetimeContractAmount = isNaN(data.lifetimeContractAmount) ? '$0' : this.formatCurrency(data.lifetimeContractAmount);
                    this.hsAccId = data.hsAccId || '';
                    this.openActivityFR = data.openActivityFR || 0;
                    this.totalActivityFR = data.totalActivityFR || 0;
                    this.openActivityHS = data.openActivityHS || 0;
                    this.totalActivityHS = data.totalActivityHS || 0;
                    this.openActivityTS = data.openActivityTS || 0;
                    this.totalActivityTS = data.totalActivityTS || 0;
                    this.frActivityAccId = data.frActivityAccId || '';
                    this.hsActivityAccId = data.hsActivityAccId || '';
                    this.tsActivityAccId = data.tsActivityAccId || '';

                }
            })
            .then((HSRevenueData) => {
                if (this.HSRevenueData.length > 0) {

                    this.hsData = this.HSRevenueData.map((rec) => ({
                        products: rec[0],
                        revenue: (rec[1] && rec[1].length > 0 && rec[1][0] != null) ? rec[1][0] : 0,
                        volume: (rec[1] && rec[1].length > 1 && rec[1][1] != null) ? rec[1][1] : 0,
                        rowStyle: ''
                    }));

                    const totalRow = {
                        products: 'Total',
                        revenue: this.hsData.reduce((acc, curr) => {
                            return acc + curr.revenue;
                        }, 0),
                        volume: this.hsData.reduce((acc, curr) => {
                            return acc + curr.volume;
                        }, 0),
                        rowStyle: 'slds-text-title_bold'
                    };
                    this.hsData.push(totalRow);
                }
            })
            .then((CGTSRevenue) => {
                this.CGTSRevenue = this.CGTSRevenueData.map((rec) => ({
                    stage: rec[0] || '',
                    productCount: rec[1] || 0,
                    totalValue: rec[2] || 0,
                }));
            })
            .catch((error) => {
                this.error = error;
                console.error('Error fetching data:', error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

     /**
     * Formats currency consistently across the UI
     */
    formatCurrency(amount) {
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD'
        }).format(amount);
    }

}