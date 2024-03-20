import { LightningElement, track } from 'lwc';
import { cloneDeep, orderBy } from 'c/lodash';

export default class SlwcTestCmp extends LightningElement {
    bestResult;

    @track defaultvalues = {};
    @track filters = {
        startDate: '2021-01-06',
        endDate: '2021-01-12'
    };
    

    @track disbaledDays = ['2023-05-30'];
    @track selectedDays = ['2023-05-01', '2023-05-02'];

    @track defaultPercentage = 0;
    @track totalPercentage = 100;
    @track progressBarData = {
        totalRecords: 100,
        processedRecords: 10,
        message: 'test'
    }

    handleOnChange(event) {
        console.log('handleOnChange', event.detail);
    }

    onCollectionOperationChanged(event) {
        console.log('>>>>>> on changed', event.detail);
    }

    connectedCallback() {
        setInterval(() => {
            let processRecords = this.progressBarData.processedRecords + 10;
            if(processRecords >= 100) processRecords = 0;
            this.progressBarData = {
                ...this.progressBarData,
                processedRecords: processRecords,
                message: `Processing...`
            }
        }, 2000)
        this.defaultvalues = {
            divisions: [
                {
                    "value": "a1b3F000002qD8jQAE",
                    "label": "Central Atlantic",
                    "recordType": "Division",
                    "selected": true
                }
            ],
            arcRegions: [
                {
                    "value": "a1b3F000002qD8tQAE",
                    "label": "Greater Alleghenies",
                    "parentId": "a1b3F000002qD8jQAE",
                    "recordType": "ARC Region",
                    "selected": true
                }
            ],
            districts: [
                {
                    "value": "a1b3F000002qD9cQAE",
                    "label": "Johnstown",
                    "parentId": "a1b3F000002qD8tQAE",
                    "recordType": "District",
                    "selected": true
                }
            ],
            collectionOperations: [
                {
                    "value": "a0g3F000001iKiZQAU",
                    "label": "L053 Altoona Mobiles",
                    "parentId": "a1b3F000002qD9cQAE",
                    "recordType": "Collection Operation",
                    "selected": false
                },
                {
                    "value": "a0g3F000001iKipQAE",
                    "label": "L053 Winchester Mobiles",
                    "parentId": "a1b3F000002qD9cQAE",
                    "recordType": "Collection Operation",
                    "selected": false
                }
            ]
        };
        
        let drives = [
            { projectedRegisteredDonors: 25 }, //25
            { projectedRegisteredDonors: 30 }, //47
            { projectedRegisteredDonors: 55 }, //60
            { projectedRegisteredDonors: 75 }, //60 26
            { projectedRegisteredDonors: 125 } //96 29
        ]

        let vehicles = [
            { presDonorCapacity: 96 },
            { presDonorCapacity: 61 },
            { presDonorCapacity: 60 },
            { presDonorCapacity: 49 },
            { presDonorCapacity: 48 },
            { presDonorCapacity: 47 },
            { presDonorCapacity: 29 },
            { presDonorCapacity: 28 },
            { presDonorCapacity: 27 },
            { presDonorCapacity: 26 },
            { presDonorCapacity: 25 },
            { presDonorCapacity: 10 },
            { presDonorCapacity: 11 }
        ];

        this.calculateNumberOfVehicles(drives, vehicles);
    }
    
    calculateNumberOfVehicles(drives, vehicles) {
        let map_drive_vehicleSets = [];
        for (let i = 0; i < drives.length; i++) {
            let vehicleSets = [];
            this.getVehicleSet(vehicleSets, drives[i].projectedRegisteredDonors, vehicles);
            vehicleSets.forEach((vehicleSet) => {
                vehicleSet.noOfVehicles = vehicleSet.vehicleIndexes.length;
            });
            map_drive_vehicleSets[i] = orderBy(vehicleSets, ['noOfVehicles', 'totalCap'], ['asc', 'asc']);
        }

        let result = {
            totalCap: 0,
            vehicleIndexes: [],
            vehicleSets: [],
        }

        this.bestResult = null;
        this.findBestResult(result, map_drive_vehicleSets, 0);
        console.log(this.bestResult);
    }

    findBestResult(result, map_drive_vehicleSets, driveIndex) {
        if (driveIndex < map_drive_vehicleSets.length) {
            let vehicleSets = map_drive_vehicleSets[driveIndex];
            for (let i = 0; i < vehicleSets.length; i++) {
                let vehicleSet = vehicleSets[i];
                let conflictedVehicle = false;
                for (let j = 0; j < vehicleSet.vehicleIndexes.length; j++) {
                    if (result.vehicleIndexes.indexOf(vehicleSet.vehicleIndexes[j]) > -1) {
                        conflictedVehicle = true;
                        break;
                    }
                }
                
                if (!conflictedVehicle) {
                    let newResult = cloneDeep(result);
                    newResult.totalCap += vehicleSet.totalCap;
                    newResult.vehicleIndexes = newResult.vehicleIndexes.concat(vehicleSet.vehicleIndexes);
                    newResult.vehicleSets.push(vehicleSet);

                    if (driveIndex == map_drive_vehicleSets.length - 1) {
                        if (!this.bestResult) {
                            this.bestResult = newResult;
                        }
                        else {
                            if (this.bestResult.vehicleIndexes.length > newResult.vehicleIndexes.length) {
                                this.bestResult = newResult;
                            }
                            else if (this.bestResult.vehicleIndexes.length == newResult.vehicleIndexes.length) {
                                if (this.bestResult.totalCap > newResult.totalCap) {
                                    this.bestResult = newResult;
                                }
                            }
                        }
                        break;
                    }
                    else {
                        this.findBestResult(newResult, map_drive_vehicleSets, driveIndex + 1);
                    }
                }
            }
        }
    }

    getVehicleSet(results, requiredCap, vehicles) {
        let nextArray = [];
        for (let j = 0; j < vehicles.length; j++) {
            let vehicleSet = {
                totalCap: vehicles[j].presDonorCapacity,
                vehicleIndexes: [j]
            }
            if (vehicleSet.totalCap >= requiredCap) {
                results.push(vehicleSet);
            }
            else {
                nextArray.push(vehicleSet);
            }
        }
        this.processNextArray(requiredCap, vehicles, results, nextArray);
    }

    processNextArray(requiredCap, vehicles, results, nextArray) {
        let newNextArray = [];

        for (let i = 0; i < nextArray.length; i++) {
            let vehicleSet = nextArray[i];
            
            for (let j = vehicleSet.vehicleIndexes[vehicleSet.vehicleIndexes.length - 1] + 1; j < vehicles.length; j++) {
                let newVehicleSet = cloneDeep(vehicleSet);
                newVehicleSet.totalCap += vehicles[j].presDonorCapacity;
                newVehicleSet.vehicleIndexes.push(j);

                if (newVehicleSet.totalCap >= requiredCap) {
                    results.push(newVehicleSet);
                }
                else if (j < vehicles.length - 1) {
                    newNextArray.push(newVehicleSet);
                }
            }
        }
        if (newNextArray.length > 0) {
            this.processNextArray(requiredCap, vehicles, results, newNextArray);
        }
    }
}