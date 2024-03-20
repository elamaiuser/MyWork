import { LightningElement } from 'lwc';
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
            typeAttributes: ['canClose', 'clickAction']
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
        }
    };
}