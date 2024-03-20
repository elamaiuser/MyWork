import { CALENDAR_FIELD_TYPE, CALENDAR_EVENT_LEVEL } from 'c/slwcConstants';
import { fireEvent } from 'c/pubsub';

export default [
  {
    objectType: 'templateAvailability',
    fieldName: 'templateAvailabilities',
    label: 'Availability',
    showLegend: false,
    level: CALENDAR_EVENT_LEVEL.ONE,
    opacity: 60,
    readonly: true,
    iconName: 'standard:resource_capacity',
    eventTypeSettingsField: (item) => {
      if(item.isAvailable) return 'Available';
      if(!item.isAvailable) return 'Unavailable';
    },
    popoverActions: [],
    infoFields: [
      {
        value: (item) => {
          if (item.isAvailable) return 'Template Available';
          if (!item.isAvailable) return 'Template Unavailable';
        },
        type: CALENDAR_FIELD_TYPE.TEXT
      },
      {
        value: [
          {
            value: 'start',
            type: CALENDAR_FIELD_TYPE.SHORT_TIME
          },
          {
            value: 'finish',
            type: CALENDAR_FIELD_TYPE.SHORT_TIME
          }
        ]
      }
    ],
    popoverFields: [
      {
        label: null,
        value: (item) => {
          if (item.isAvailable) return 'Template';
          if (!item.isAvailable) return 'Template';
        },
        type: CALENDAR_FIELD_TYPE.TEXT,
        isHeader: true
      },
      {
        label: null,
        value: (item) => {
          if (item.isAvailable) return 'Available';
          if (!item.isAvailable) return 'Unavailable';
        },
        isHeader: true
      },
      {
        label: 'From',
        value: 'start',
        type: CALENDAR_FIELD_TYPE.DATETIME,
        isHeader: false
      },
      {
        label: 'To',
        value: 'finish',
        type: CALENDAR_FIELD_TYPE.DATETIME,
        isHeader: false
      }
    ]
  },
  {
    objectType: 'clientAvailability',
    fieldName: 'clientAvailabilities',
    label: 'Availability',
    showLegend: true,
    level: CALENDAR_EVENT_LEVEL.TWO,
    iconName: 'standard:resource_capacity',
    eventTypeSettingsField: (item) => {
      if(item.isAvailable) return 'Available';
      if(!item.isAvailable) return 'Unavailable';
    },
    popoverFields: [
      {
        label: null,
        value: 'name',
        type: CALENDAR_FIELD_TYPE.TEXT,
        isHeader: true
      },
      {
        label: null,
        value: (item) => {
          if (item.isAvailable) return 'Available';
          if (!item.isAvailable) return 'Unavailable';
        },
        isHeader: true
      },
      {
        label: 'From',
        value: 'start',
        type: CALENDAR_FIELD_TYPE.DATETIME,
        isHeader: false
      },
      {
        label: 'To',
        value: 'finish',
        type: CALENDAR_FIELD_TYPE.DATETIME,
        isHeader: false
      }
    ],
    popoverActions: [
      {
        label: 'Edit',
        iconName: 'utility:edit',
        callback: (item, pageRef) => {
          let eventValues = { action: "edit", model: item };
          fireEvent(pageRef, 'showClientAvailabilityModal', eventValues);
        }
      },
      {
        label: 'Delete',
        iconName: 'utility:delete',
        className: 'btn-delete',
        callback: (item, pageRef) => {
          let eventValues = { action: "delete", model: item };
          fireEvent(pageRef, 'showClientAvailabilityModal', eventValues);
        }
      }
    ],
    infoFields: [
      {
        value: (item) => {
          if (item.isAvailable) return 'Available';
          if (!item.isAvailable) return 'Unavailable';
        },
        type: CALENDAR_FIELD_TYPE.TEXT
      },
      {
        value: [
          {
            value: 'start',
            type: CALENDAR_FIELD_TYPE.SHORT_TIME
          },
          {
            value: 'finish',
            type: CALENDAR_FIELD_TYPE.SHORT_TIME
          }
        ]
      }
    ]
  },
  {
    objectType: 'drive',
    fieldName: 'drives',
    label: 'Drive',
    showLegend: true,
    level: CALENDAR_EVENT_LEVEL.THREE,
    iconName: 'custom:custom63',
    eventTypeSettingsField: 'typeOfDrive',
    popoverFields: [
      {
        label: null,
        value: 'name',
        type: CALENDAR_FIELD_TYPE.TEXT,
        isHeader: true
      },
      {
        label: null,
        value: 'typeOfDrive',
        type: CALENDAR_FIELD_TYPE.TEXT,
        isHeader: true
      },
      {
        label: 'Drive Site',
        value: (item) => {
          return item.driveSite.name;
        },
        type: CALENDAR_FIELD_TYPE.TEXT,
        isHeader: false
      },
      {
        label: 'From',
        value: 'start',
        type: CALENDAR_FIELD_TYPE.DATETIME,
        isHeader: false
      },
      {
        label: 'To',
        value: 'finish',
        type: CALENDAR_FIELD_TYPE.DATETIME,
        isHeader: false
      }
    ],
    popoverActions: [
    ],
    infoFields: [
      {
        value: 'name',
        type: CALENDAR_FIELD_TYPE.TEXT
      },
      {
        value: 'typeOfDrive',
        type: CALENDAR_FIELD_TYPE.TEXT
      },
      {
        value: [
          {
            value: 'start',
            type: CALENDAR_FIELD_TYPE.SHORT_TIME
          },
          {
            value: 'finish',
            type: CALENDAR_FIELD_TYPE.SHORT_TIME
          }
        ]
      }
    ]
  }
]