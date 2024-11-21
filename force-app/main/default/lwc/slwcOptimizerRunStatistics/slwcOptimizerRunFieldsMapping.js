export const fieldMap = {
    'totalPlannedAllocations': {
        label: 'Total Planned Allocations',
        type: 'Statistics',        
        solviceConstraint: '',
        displayOrder: 1
    },
    'totalSchedAllocations': {
        label: 'Total Scheduled Allocations',
        type: 'Statistics',        
        solviceConstraint: '',
        displayOrder: 2
    },
    'totalUnSchedAllocations': {
        label: 'Total Unscheduled Allocations',
        type: 'Statistics',            
        solviceConstraint: '',
        displayOrder: 3
    },
    'totalResourceSched': {
        label: 'Total Resource Scheduled',
        type: 'Statistics',            
        solviceConstraint: '',
        displayOrder: 4
    },
    'totalResourceUnSched': {
        label: 'Total Resource Unscheduled',
        type: 'Statistics',            
        solviceConstraint: '',
        displayOrder: 5
    },
    'totalSchedTime': {
        label: 'Total Scheduled Time (Minutes)',
        type: 'Statistics',            
        solviceConstraint: '',
        displayOrder: 6
    },
    'totalTravelTime': {
        label : 'Total Travel Time (Minutes)',
        type: 'Statistics',            
        solviceConstraint: '',
        displayOrder: 7
    },  
    'totalTravelDistances': {
        label : 'Total Travel Distance (Meters)',
        type: 'Statistics',            
        solviceConstraint: '',
        displayOrder: 8
    },
    'maxTravelTimeAllocations': {
        label : 'Max Travel Time for the Allocations (Minutes)',
        type: 'Statistics',            
        solviceConstraint: '',
        displayOrder: 9
    },
    'avgNumAllocationsPerResource': {
        label : 'Average number of allocations per Resource',
        type: 'Statistics',            
        solviceConstraint: '',
        displayOrder: 10
    },
    'hardConstraintScore': {
        label : 'Hard Constraints Score',
        type: 'Statistics',            
        solviceConstraint: '',
        displayOrder: 11
    },
    'softConstraintScore': {
        label : 'Soft Constraints Score',
        type: 'Statistics',            
        solviceConstraint: '',
        displayOrder: 12
    },
    'accountPreferences': {
        label : 'Account Preferences',
        type: 'Weights',            
        solviceConstraint : 'pref',
        displayOrder: 13
    },
    'sitePreferences': {
        label : 'Site Preferences',
        type: 'Weights',            
        solviceConstraint : 'pref',
        displayOrder: 14
    },
    'geoPreferences': {
        label : 'Geographic Preferences',
        type: 'Weights',            
        solviceConstraint : 'distanceAL',
        displayOrder: 15
    },
    'hireDateSkills': {
        label : 'Hire Date',
        type: 'Weights',            
        solviceConstraint : 'softSkillLevel',
        displayOrder: 16
    },
    'rolePrioritySkills': {
        label : 'Role Priorities',
        type: 'Weights',            
        solviceConstraint : 'softSkillLevel',
        displayOrder: 17
    },
    'startDate': {
        label : 'Scheduling Period Start',
        type: 'Parameters',            
        solviceConstraint: '',
        displayOrder: 18
    },
    'endDate': {
        label : 'Scheduling Period End',
        type: 'Parameters',            
        solviceConstraint: '',
        displayOrder: 19
    },
    'timeZone': {
        label : 'Timezone',
        type: 'Parameters',            
        solviceConstraint: '',
        displayOrder: 20
    }  
};