import { CALENDAR_FIELD_TYPE, JOB_ALLOCATION_STATUS } from 'c/slwcConstants';
import { fireEvent } from 'c/pubsub';

export default [
  {
    objectType: 'activity',
    fieldName: 'activities',
    label: 'Activity',
    showLegend: true,
    iconName: 'custom:custom2',
    eventTypeSettingsField: (item) => {
      return item.activity.eventType
    },
    uiSettings: {
      monthCardBackgroundColor: 'rgb(217 237 255)'
    },
    popoverFields: [
      {
        label: 'Name',
        value: (item) => item.activity.activityTitle || item.activity.name,
        type: CALENDAR_FIELD_TYPE.TEXT,
        isHeader: true
      },
      {
        label: 'Type',
        value: (item) => item.activity.eventType,
        type: CALENDAR_FIELD_TYPE.TEXT,
        isHeader: true
      },
      {
        label: 'Sub-Type',
        value: (item) => item.activity.subtype,
        type: CALENDAR_FIELD_TYPE.TEXT,
        isHeader: true
      },
      {
        label: 'Start',
        value: (item) => item.activity.start,
        type: CALENDAR_FIELD_TYPE.DATETIME,
        isHeader: false
      },
      {
        label: 'End',
        value: (item) => item.activity.finish,
        type: CALENDAR_FIELD_TYPE.DATETIME,
        isHeader: false
      },
      {
        label: 'Address',
        value: (item) => item.activity.address,
        type: CALENDAR_FIELD_TYPE.TEXT,
        isHeader: false
      },
      {
        label: 'Notes',
        value: (item) => item.activity.notes,
        type: CALENDAR_FIELD_TYPE.TEXT,
        isHeader: false
      }
    ],
    popoverActions: [
      {
        label: 'Call Out',
        className: 'btn-delete',
        iconName: 'utility:outbound_call',
        hideIf: (item) => {
          if(!item.canCallOut) return true;
          return !item.activity.isGroupActivity;
        },
        callback: (item, pageRef) => {
          let eventValues = { model: item };
          fireEvent(pageRef, 'showCallOutModal', eventValues);
        }
      }
    ],
    infoFields: [
      {
        value: (item) => item.activity.activityTitle || item.activity.name,
        type: CALENDAR_FIELD_TYPE.TEXT,
      },
      {
        value: [
          {
            value: (item) => item.start,
            type: CALENDAR_FIELD_TYPE.SHORT_TIME
          },
          {
            value: (item) => item.finish,
            type: CALENDAR_FIELD_TYPE.SHORT_TIME
          }
        ]
      }
    ]
  },
  {
    objectType: 'jobAllocation',
    fieldName: 'jobAllocations',
    label: 'Job Allocation',
    showLegend: true,
    iconName: 'custom:custom44',
    eventTypeSettingsField: (item) => {
      return item.status
    },
    uiSettings: {
      monthCardBackgroundColor: 'rgb(217 237 255)'
    },
    popoverFields: [
      {
        label: null,
        value: (item) => item.job.eventType,
        type: CALENDAR_FIELD_TYPE.TEXT,
        isHeader: true
      },
      {
        label: null,
        value: (item) => item.status,
        type: CALENDAR_FIELD_TYPE.TEXT,
        isHeader: true
      },
      {
        label: 'Additional Roles',
        value: (item) => {
          return (item.additionalRoles || []).join(', ')
        },
        type: CALENDAR_FIELD_TYPE.TEXT,
        isHeader: false,
        hideIf: (item) => {
          return !item.additionalRoles
        },
      },
      {
        label: 'Job Name',
        value: (item) => item.job.name,
        type: CALENDAR_FIELD_TYPE.TEXT,
        isHeader: false
      },
      {
        label: 'Job Status',
        value: (item) => item.job.jobStatus,
        type: CALENDAR_FIELD_TYPE.TEXT,
        isHeader: false
      },
      {
        label: 'Drive Name',
        value: 'driveName',
        type: CALENDAR_FIELD_TYPE.TEXT,
        isHeader: false
      },
      {
        label: 'Drive Shift',
        value: 'driveShiftName',
        type: CALENDAR_FIELD_TYPE.TEXT,
        isHeader: false
      },
      {
        label: 'Primary Scheduler',
        value: [{
          value: (item) => item.job.primarySchedulerName,
          type: CALENDAR_FIELD_TYPE.TEXT
        }, {
          value: (item) => item.job.primarySchedulerMobilePhone,
          type: CALENDAR_FIELD_TYPE.TEXT
        }], 
        hideIf: (item) => {
          return !item.job.primarySchedulerId
        },
        isHeader: false
      },
      {
        label: 'Collections Manager',
        value: [{
          value: (item) => item.job.collectionsManagerName,
          type: CALENDAR_FIELD_TYPE.TEXT
        }, {
          value: (item) => item.job.collectionsManagerMobilePhone,
          type: CALENDAR_FIELD_TYPE.TEXT
        }], 
        hideIf: (item) => {
          return !item.job.collectionsManagerId
        },
        isHeader: false
      },
      {
        label: 'Start',
        value: (item) => item.start,
        type: CALENDAR_FIELD_TYPE.DATETIME,
        isHeader: false
      },
      {
        label: 'End',
        value: (item) => item.finish,
        type: CALENDAR_FIELD_TYPE.DATETIME,
        isHeader: false
      }
    ],
    popoverActions: [
      {
        label: 'RTV Feedback',
        iconName: 'utility:form',
        callback: (item, pageRef) => {
          let eventValues = { model: item };
          fireEvent(pageRef, 'showSiteFeedbackModal', eventValues);
        }
      },
      {
        label: 'Drive Worksheet',
        iconName: 'utility:form',
        callback: (item, pageRef) => {
          let eventValues = { model: item };
          fireEvent(pageRef, 'openDriveWorksheet', eventValues);
        }
      },
      {
        label: 'Operation Record',
        iconName: 'utility:form',
        callback: (item, pageRef) => {
          let eventValues = { model: item };
          fireEvent(pageRef, 'showOperationRecordModal', eventValues);
        }
      },
      {
        label: 'Call Out',
        className: 'btn-delete',
        iconName: 'utility:outbound_call',
        hideIf: (item) => {
          if(!item.canCallOut) return true;
          
          return [JOB_ALLOCATION_STATUS.DISPATCHED, JOB_ALLOCATION_STATUS.CONFIRMED, 
            JOB_ALLOCATION_STATUS.EN_ROUTE, JOB_ALLOCATION_STATUS.CHECKED_IN, 
            JOB_ALLOCATION_STATUS.IN_PROGRESS
          ].indexOf(item.status) === -1
        },
        callback: (item, pageRef) => {
          let eventValues = { model: item };
          fireEvent(pageRef, 'showCallOutModal', eventValues);
        }
      },
    ],
    infoFields: [
      {
        value: (item) => item.job.eventType,
        type: CALENDAR_FIELD_TYPE.TEXT,
      },
      {
        value: (item) => {
          return (item.additionalRoles || []).join(', ');
        },
        type: CALENDAR_FIELD_TYPE.TEXT,
      },
      {
        value: 'driveName',
        type: CALENDAR_FIELD_TYPE.TEXT
      },
      {
        value: 'driveShiftName',
        type: CALENDAR_FIELD_TYPE.TEXT
      },
      {
        value: [
          {
            value: (item) => item.start,
            type: CALENDAR_FIELD_TYPE.SHORT_TIME
          },
          {
            value: (item) => item.finish,
            type: CALENDAR_FIELD_TYPE.SHORT_TIME
          }
        ]
      }
    ]
  }
]