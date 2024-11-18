import { LightningElement, api } from 'lwc';
import { optimizationRunService } from 'c/dataService';
import * as autoMapper from 'c/autoMapper';
import { fieldMap } from './slwcOptimizerRunFieldsMapping.js';
import { DateTime } from 'c/luxon';



export default class SlwcOptimizerRunStatistics extends LightningElement {
    optimizerRunStatistics;
    optimizerRunParameters;
    optimizerRunWeights;
    _optimizationRun;
    initialized = false;
    showSpinnerCount = 0;
    weightColumns = [
        { label: 'ARC Scoring Factor', fieldName: 'OptLabel', hideDefaultActions: true },
        { label: 'Solvice Constraint', fieldName: 'OptSolvice', hideDefaultActions: true },
        { label: 'Weights', fieldName: 'OptValue', hideDefaultActions: true },                       
    ];     
    
    @api 
    get optimizationRun() {
        return this._optimizationRun;
    }

    set optimizationRun(value) {
        this._optimizationRun = value;
    }    

    renderedCallback(){          
        if(!this.initialized) {
            this.getOptimizerRunStatistics(this.optimizationRun.id);
            this.initialized = true;
        }
    }

    getOptimizerRunStatistics(OptId) {
        let service = new optimizationRunService();
        this.showLoading();
        return service.getOptimizationRunStatistics({optimizationId: OptId})
        .then((result) => {
            let data = autoMapper.autoMapperInstance.mapToArray('sked_Optimization_Run__c', result.returnedData || []);
            this.populateOptimizerRunStatistics(data[0]);            
        })
        .catch(error => this.exceptionHandler(error, true))
        .finally(this.hideLoading);
    }

    exceptionHandler = (error, silentError = false) => {
        console.log(error);
    }

    populateOptimizerRunStatistics(optimizerRunData) {              
        let mappedData = Object.keys(optimizerRunData).map((key) => {
            const {label, type, solviceConstraint, displayOrder} = fieldMap[key] || {
                label: '',
                type: '',                
                solviceConstraint: '',
                displayOrder: 0
            };
             let value = label ? optimizerRunData[key] : 0;

             if (label.includes('Period')){
                value = DateTime.fromFormat(value, 'yyyy-MM-dd').toFormat('MMM dd, yyyy');
             }
             return {
                OptLabel: label,
                OptValue: value,
                OptType: type,                
                OptSolvice: solviceConstraint,
                OptOrder: displayOrder
            };
        }).sort((a,b) => a.OptOrder - b.OptOrder);
                
        this.optimizerRunStatistics = mappedData.filter(item => item.OptType === 'Statistics');
        this.optimizerRunParameters = mappedData.filter(item => item.OptType === 'Parameters');
        this.optimizerRunWeights = mappedData.filter(item => item.OptType === 'Weights');
    }

    handleClose(){
        const closeEvent = new CustomEvent('close', {});
        this.dispatchEvent(closeEvent);
    }

    showLoading = () => {
        this.showSpinnerCount++;
    }

    hideLoading = () => {
        this.showSpinnerCount--;
        if(this.showSpinnerCount < 0) {
            this.showSpinnerCount = 0;
        }
    }    
}