import userInfoRender from './userInfoRender.html';
import userUrlRender from './userUrlRender.html';
import linkedDriveRender from './linkedDriveRender.html';
import driveBagRender from './driveBagRender.html';
import actionButton from './actionButton.html';
import plannedProductivity from './plannedProductivity.html';
import linkDriveButton from './linkDriveButton.html';
import optimizationRunButton from './optimizationRunButton.html';
import driveNameRender from './driveNameRender.html';
import timeRender from './timeRender.html';
import jobQuantityRender from './jobQuantityRender.html';
import resourcesRender from './resourcesRender.html';
import linkedDriveDrives from './linkedDriveDrives.html';
import optimizationRunResultCell from './optimizationRunResultCell.html';
import tradingEventRender from './tradingEventRender.html';
import traderSelectionRender from './traderSelectionRender.html';

import LightningDatatable from 'lightning/datatable';

export default class SlwcCustomDatatable extends LightningDatatable {
    static customTypes = {
        userInfo: {
            template: userInfoRender,
            typeAttributes: ['showPhoto'],
        },
        userUrl: {
            template: userUrlRender,
            typeAttributes: ['user']
        },
        linkedDrive: {
            template: linkedDriveRender,
            typeAttributes: ['iconClicked']
        },
        linkDriveButton: {
            template: linkDriveButton,
            typeAttributes: ['isLinked', 'isCurrentDrive', 'clickAction']
        },
        driveBag:{
            template: driveBagRender,
            typeAttributes: ['showDriveBag']
        },
        actionButton:{
            template: actionButton,
            typeAttributes: ['rowActions']
        },
        optimizationRunButton:{
            template: optimizationRunButton,
            typeAttributes: ['canClose', 'isStatusCompleted','clickAction'] // HRP-12509
        },
        plannedProductivity: {
            template: plannedProductivity,
            typeAttributes: []
        },
        driveName: {
            template: driveNameRender,
            standardCellLayout: true,
            typeAttributes: []
        },
        time: {
            template: timeRender,
            standardCellLayout: true,
            typeAttributes: []
        },
        jobQuantity: {
            template: jobQuantityRender,
            standardCellLayout: true,
            typeAttributes: ['showAPTQuantity', 'aptQuantity', 'vphhQuantity', 'quantity']
        },
        resources: {
            template: resourcesRender,
            standardCellLayout: true,
            typeAttributes: []
        },
        linkedDriveDrives: {
            template: linkedDriveDrives,
            standardCellLayout: true,
            typeAttributes: []
        },
        optimizationRunResultCell: {
            template: optimizationRunResultCell,
            typeAttributes: ['cellValue']
        },
        tradingEvent: {
            template: tradingEventRender,
            typeAttributes: ['label']
        },
        traderSelection: {
            template: traderSelectionRender,
            typeAttributes: ['classes', 'photoUrl', 'name', 'category', 'clickAction']
        }
    };
}