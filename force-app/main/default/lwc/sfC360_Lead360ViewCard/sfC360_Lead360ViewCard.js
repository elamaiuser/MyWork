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

import queryDataCloud from '@salesforce/apex/SFC360_Lead360ViewController.queryDataCloud';
import queryActivityModal from '@salesforce/apex/SFC360_Lead360ViewController.queryActivityModal';
import queryRelatedAccountDetails from '@salesforce/apex/SFC360_Lead360ViewController.queryRelatedAccountDetails';

import GREEN from '@salesforce/resourceUrl/greenIcon';
import GRAY from '@salesforce/resourceUrl/grayIcon';
//import SHOW_HS_DATA from '@salesforce/label/c.Show_HS_Financial_Data';

const hsColumns = [
    { label: 'Products', fieldName: 'products', type: 'text', cellAttributes: { class: { fieldName: 'rowStyle' } } },
    { label: 'Revenue', fieldName: 'revenue', type: 'currency', cellAttributes: { class: { fieldName: 'rowStyle' } } },
    { label: 'Volume', fieldName: 'volume', type: 'number', cellAttributes: { class: { fieldName: 'rowStyle' } } },
];

const cgtsColumns = [
    { label: 'Contract Stage', fieldName: 'stage', type: 'text' },
    { label: 'Total Product Count', fieldName: 'productCount', type: 'number' },
    { label: 'Total Value', fieldName: 'totalValue', type: 'currency' },
];

const contractDataColumns = [
    { label: 'Contract Number', fieldName: 'ContractNumber', type: 'text' },
    { label: 'Type', fieldName: 'Type', type: 'text' },
    { label: 'Status', fieldName: 'Status', type: 'text' },
    { label: 'Is Active', fieldName: 'IsActive', type: 'text' },
    { label: 'Start Date', fieldName: 'StartDate', type: 'text' },
    { label: 'End Date', fieldName: 'EndDate', type: 'text' },
    { label: 'Total Amount', fieldName: 'TotalAmount', type: 'currency' },
];

const accDetailsDataColumns = [
    { label: 'Org Name', fieldName: 'orgName', type: 'text', initialWidth: 150, hideDefaultActions: true },
    { label: 'Account Name', fieldName: 'accountName', type: 'text', initialWidth: 200, hideDefaultActions: true },
    { label: 'Address', fieldName: 'accAddress', type: 'text', initialWidth: 250, hideDefaultActions: true },
    { label: 'City', fieldName: 'accCity', type: 'text', initialWidth: 120, hideDefaultActions: true },
    { label: 'State', fieldName: 'accState', type: 'text', initialWidth: 80, hideDefaultActions: true },
    { label: 'Zip Code', fieldName: 'accZipcode', type: 'text', initialWidth: 100, hideDefaultActions: true },       
    { label: 'Phone Number', fieldName: 'accPhone', type: 'text', initialWidth: 120, hideDefaultActions: true },
    { label: 'Account Manager', fieldName: 'accManager', type: 'text', initialWidth: 200, hideDefaultActions: true },
    { label: 'Account Id', fieldName: 'accRecId', type: 'text', initialWidth: 150, hideDefaultActions: true }
];

const giftDetailsDataColumns = [
    { label: 'Account Id', fieldName: 'accRecId', type: 'text' },
    { label: 'Account Name', fieldName: 'accountName', type: 'text' },
    { label: 'Gift Amount', fieldName: 'giftAmount', type: 'currency' }
];

const driveDetailsDataColumns = [
    { label: 'Drive Id', fieldName: 'driveRecId', type: 'text' },
    { label: 'Drive Name', fieldName: 'driveName', type: 'text' },
    { label: 'Drive Date', fieldName: 'driveDate', type: 'text' },
    { label: 'Org Name', fieldName: 'orgName', type: 'text' },
    { label: 'Drive Status', fieldName: 'driveStatus', type: 'text' }
];

const courseDetailsDataColumns = [
    { label: 'Course Id', fieldName: 'courseId', type: 'text' },
    { label: 'Course Name', fieldName: 'trainingClass', type: 'text' },
    { label: 'Account Name', fieldName: 'accountName', type: 'text' }
];

export default class SfC360_Lead360ViewCard extends LightningElement {

    @track hsData = [];
    @track CGTSRevenue = [];
    @api objectApiName;
    @api recordId;

    @track accAmDetails = {};
    @track HSRevenueData = [];
    @track CGTSRevenueData = [];
    @track groupedActivities = [];

    isLoading = false;
    isModalOpen = false;
    @track isModalLoading = false;
    modalType = null;
    modalTitle = '';

    header = '';
    headerIcon = '';

    recordsCompleted = 0;
    plannedDrives = 0;
    plannedCourses = 0;
    coursesCompleted = 0;
    numberOfAccounts = 0;

    frGiftCount = '';
    frTotalGiftAmount = '';
    frTotalGiftAmountVal = '';
    lifetimeContractCount = '';
    lifetimeContractAmount = '';

    unifiedAccId;
    hsAccId;
    frActivityAccId;
    hsActivityAccId;
    tsActivityAccId;

    openActivityFR = 0;
    totalActivityFR = 0;
    openActivityHS = 0;
    totalActivityHS = 0;
    openActivityTS = 0;
    totalActivityTS = 0;

    accountDetailsData = [];
    giftDetailsData = [];
    driveDetailsData = [];
    courseDetailsData = [];
    contractData = [];

    hsColumns = hsColumns;
    cgtsColumns = cgtsColumns;
    contractDataColumns = contractDataColumns;
    accDetailsDataColumns = accDetailsDataColumns;
    giftDetailsDataColumns = giftDetailsDataColumns;
    driveDetailsDataColumns = driveDetailsDataColumns;
    courseDetailsDataColumns = courseDetailsDataColumns;

    greenIcon = GREEN;
    grayIcon = GRAY;
    //showHSData = SHOW_HS_DATA;

    get isAccountModal() { return this.modalType === 'ACCOUNT'; }
    get isGiftModal() { return this.modalType === 'GIFT'; }
    get isDriveModal() { return this.modalType === 'DRIVE'; }
    get isCourseModal() { return this.modalType === 'COURSE'; }
    get isActivityModal() { return this.modalType === 'ACTIVITY'; }
    get isContractModal() { return this.modalType === 'CONTRACT'; }
    get hasDriveDetails() { return Array.isArray(this.driveDetailsData) && this.driveDetailsData.length > 0; }
    get hasGiftDetails() { return Array.isArray(this.giftDetailsData) && this.giftDetailsData.length > 0; }
    get hasAccountDetails() { return Array.isArray(this.accountDetailsData) && this.accountDetailsData.length > 0; }
    get hasContractDetails() { return Array.isArray(this.contractData) && this.contractData.length > 0; }
    get showFinancialData() { return this.showHSData.toLowerCase() === 'true'; }
    get wiredParams() {
        return {
            dataSourceObjectId: this.objectApiName,
            sourceRecId: this.recordId,
        };
    }

    // Safer getter to check API name presence without setting variables
    get hasObjectApiName() {
        return !!this.objectApiName;
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
            const baseClass = 'slds-timeline__item';

            const typeClass =
                activity.type === 'Email' ? 'slds-timeline__item_email' : 
                activity.type === 'Task' ? 'slds-timeline__item_task' : 
                activity.type === 'Call' ? 'slds-timeline__item_call' : 
                activity.type === 'Event' ? 'slds-timeline__item_event' : '';

            return {
                ...activity,
                typeIcon: this.getIconName(activity.type),
                isTask: activity.type === 'Task',
                isEmail: activity.type === 'Email',
                isCall: activity.type === 'Call',
                isEvent: activity.type === 'Event',
                isClosed: activity.isClosed === 'true',
                timelineItemClass: `${baseClass} ${typeClass}`
            };
        };

        const transformedGroups = this.groupedActivities.map(group => {
            const values = [];

            group.activities.forEach(activity => {
                const isUpcoming = activity.isClosed === 'false' && activity.isUpcoming;

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

        const filteredGroups = transformedGroups.filter(group => group.values.length > 0);

        if (upcomingAndOverdue.length) {
            filteredGroups.unshift({
                key: 'Upcoming & Overdue',
                values: upcomingAndOverdue,
                isUpcomingGroup: true
            });
        }

        return filteredGroups;
    }

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

    handleModalClickActivity(event) {
        event.preventDefault();
        const accId = event.currentTarget.dataset.accid;
        if (!accId) return;
        this.openModal('ACTIVITY', 'Activities');
        this.fetchActivity(accId);
    }

    handleModalClickAccountDetails(event) {
        event.preventDefault();
        this.openModal('ACCOUNT', 'Account Details');
        this.fetchAccountdetails(this.unifiedAccId);
    }

    handleModalClickGiftDetails(event) {
        event.preventDefault();
        const giftType = event.currentTarget.dataset.type;
        const valueClicked = giftType === 'giftCount' ? Number(this.frGiftCount) : Number(this.frTotalGiftAmountVal);
        this.openModal('GIFT', 'Gift Details');
        if (valueClicked === 0) {
            this.giftDetailsData = [];
            this.isModalLoading = false;
            return;
        }
        // Assuming fetchGiftdetails exists in the full file
        if(this.fetchGiftdetails) this.fetchGiftdetails(this.unifiedAccId);
    }

    handleModalClickDriveDetails(event) {
        event.preventDefault();
        const driveType = event.currentTarget.dataset.type;
        const valueClicked = driveType === 'Completed' ? Number(this.recordsCompleted) : Number(this.plannedDrives);
        this.openModal('DRIVE', 'Drive Details');
        if (valueClicked === 0) {
            this.driveDetailsData = [];
            this.isModalLoading = false;
            return;
        }
        if(this.fetchDrivedetails) this.fetchDrivedetails(this.unifiedAccId, driveType);
    }

    handleModalClickCourseDetails(event) {
        event.preventDefault();
        const courseType = event.currentTarget.dataset.type;
        const valueClicked = courseType === 'Completed' ? Number(this.coursesCompleted) : Number(this.plannedCourses);
        this.openModal('COURSE', 'Course Details');
        if (valueClicked === 0) {
            this.courseDetailsData = [];
            this.isModalLoading = false;
            return;
        }
        if(this.fetchCoursedetails) this.fetchCoursedetails(this.unifiedAccId, courseType);
    }

    getIconName(type) {
        switch ((type || '').toLowerCase()) {
            case 'email':
                return 'standard:email';
            case 'call':
                return 'action:log_a_call';
            case 'event':
                return 'standard:event';
            default:
                return 'standard:task';
        }
    }

    connectedCallback() {
        // Set variables here instead of during render getter! 
        this.header = this.objectApiName === 'Account' ? 'Account 360' : 'Lead 360';
        this.headerIcon = this.objectApiName === 'Account' ? 'standard:account' : 'standard:lead';
        this.loadData();
    }

    fetchAccountdetails(recId) {
        const unifiedAccId = recId;
        queryRelatedAccountDetails({ unifiedAccId })
            .then((data) => {
                if (data) {
                    this.accountDetailsData = data.accountData || [];
                }
            })
            .catch((error) => {
                this.isModalOpen = false;
                console.error('Error fetching data:', error);
            })
            .finally(() => {
                this.isModalLoading = false;
            });
    }

    fetchActivity(recId) {
        this.groupedActivities = [];
        queryActivityModal({ accId: recId })
            .then((data) => {
                if (data && data.activityData) {
                    this.groupedActivities = data.activityData;
                }
            })
            .catch((error) => {
                this.isModalOpen = false;
                console.error('Error fetching activities:', error);
            })
            .finally(() => {
                this.isModalLoading = false;
            });
    }

    loadData() {
        const params = this.wiredParams;
        this.isLoading = true;
        queryDataCloud({ params })
            .then((data) => {
                if (data) {
                    this.unifiedAccId = data.unifiedId || '';
                    this.accAmDetails = data.accAmDetails || {};
                    this.recordsCompleted = isNaN(parseFloat(data.recordsCompleted).toString()) ? '0' : parseFloat(data.recordsCompleted).toString();
                    this.plannedDrives = isNaN(parseFloat(data.plannedDrives).toString()) ? '0' : parseFloat(data.plannedDrives).toString();
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
            .then(() => {
                if (this.HSRevenueData.length > 0) {
                    this.hsData = this.HSRevenueData.map((rec) => ({
                        products: rec[0],
                        revenue: (rec[1] && rec[1].length > 0 && rec[1][0] != null) ? rec[1][0] : 0,
                        volume: (rec[1] && rec[1].length > 1 && rec[1][1] != null) ? rec[1][1] : 0,
                        rowStyle: ''
                    }));
                    const totalRow = {
                        products: 'Total',
                        revenue: this.hsData.reduce((acc, curr) => acc + curr.revenue, 0),
                        volume: this.hsData.reduce((acc, curr) => acc + curr.volume, 0),
                        rowStyle: 'slds-text-title_bold'
                    };
                    this.hsData.push(totalRow);
                }
            })
            .then(() => {
                this.CGTSRevenue = this.CGTSRevenueData.map((rec) => ({
                    stage: rec[0] || '',
                    productCount: rec[1] || 0,
                    totalValue: rec[2] || 0,
                }));
            })
            .catch((error) => {
                console.error('Error fetching data:', error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    formatCurrency(amount) {
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD'
        }).format(amount);
    }
}