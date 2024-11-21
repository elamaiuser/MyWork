export default {
    "dcrPeriods": [
        {
            "id": 1,
            "name": "Greater 12 weeks",
            "sortOrder": 1,
            "backgroundColor": "#d9ffdf"
        },
        {
            "id": 2,
            "name": "12 wk - 6 wk",
            "sortOrder": 2,
            "backgroundColor": "#fdf6f7"
        }
    ],
    "dcrRoles": [
        {
            "id": 1,
            "dcrPeriodId": 1,
            "role": "AM",
            "sortOrder": 1
        },
        {
            "id": 2,
            "dcrPeriodId": 2,
            "role": "DM",
            "sortOrder": 5
        },
        {
            "id": 3,
            "dcrPeriodId": 1,
            "role": "APS",
            "sortOrder": 3
        },
        {
            "id": 4,
            "dcrPeriodId": 2,
            "role": "AM",
            "sortOrder": 4
        },
        {
            "id": 5,
            "dcrPeriodId": 1,
            "role": "DM",
            "sortOrder": 2
        },
        {
            "id": 6,
            "dcrPeriodId": 2,
            "role": "APS",
            "sortOrder": 6
        }
    ],
    "dcrFields": [
        {
            "id": 1,
            "fieldApiName": "sked_Appointment_Slots",
            "fieldLabel": "Appointment Slots",
            "editable": true,
            "dpUpdated": true
        },
        {
            "id": 2,
            "fieldApiName": "sked_Drive_Keyword ",
            "fieldLabel": "Drive Keyword ",
            "editable": false,
            "dpUpdated": false
        },
        {
            "id": 3,
            "fieldApiName": "sked_Vehicle",
            "fieldLabel": "Vehicle",
            "editable": true,
            "dpUpdated": true
        }
    ],
    "dcrRoleFields": [
        {
            "id": 1,
            "dcrRoleId": 6,
            "dcrFieldId": 1,
            "action": "X"
        },
        {
            "id": 2,
            "dcrRoleId": 6,
            "dcrFieldId": 2,
            "action": "Y"
        },
        {
            "id": 3,
            "dcrRoleId": 6,
            "dcrFieldId": 3,
            "action": "Process"
        },
        {
            "id": 4,
            "dcrRoleId": 2,
            "dcrFieldId": 1,
            "action": "Y"
        },
        {
            "id": 5,
            "dcrRoleId": 2,
            "dcrFieldId": 2,
            "action": "System"
        },
        {
            "id": 6,
            "dcrRoleId": 2,
            "dcrFieldId": 3,
            "action": "Process"
        },
        {
            "id": 7,
            "dcrRoleId": 5,
            "dcrFieldId": 1,
            "action": "System"
        },
        {
            "id": 8,
            "dcrRoleId": 5,
            "dcrFieldId": 2,
            "action": "Y"
        },
        {
            "id": 9,
            "dcrRoleId": 5,
            "dcrFieldId": 3,
            "action": "System"
        },
        {
            "id": 7,
            "dcrRoleId": 4,
            "dcrFieldId": 1,
            "action": "System"
        },
        {
            "id": 8,
            "dcrRoleId": 4,
            "dcrFieldId": 2,
            "action": "Y"
        },
        {
            "id": 9,
            "dcrRoleId": 4,
            "dcrFieldId": 3,
            "action": "System"
        },
        {
            "id": 7,
            "dcrRoleId": 3,
            "dcrFieldId": 1,
            "action": "System"
        },
        {
            "id": 8,
            "dcrRoleId": 3,
            "dcrFieldId": 2,
            "action": "Y"
        },
        {
            "id": 9,
            "dcrRoleId": 3,
            "dcrFieldId": 3,
            "action": "System"
        },
        {
            "id": 7,
            "dcrRoleId": 1,
            "dcrFieldId": 1,
            "action": "System"
        },
        {
            "id": 8,
            "dcrRoleId": 1,
            "dcrFieldId": 2,
            "action": "Y"
        },
        {
            "id": 9,
            "dcrRoleId": 1,
            "dcrFieldId": 3,
            "action": "System"
        }
    ]
}