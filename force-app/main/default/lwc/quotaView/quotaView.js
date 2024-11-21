import { LightningElement, wire } from 'lwc';
import { publish, subscribe, createMessageContext, releaseMessageContext } from 'lightning/messageService';
import periodRefMC from '@salesforce/messageChannel/PeriodReferenceMessageChannel__c';
import getQuota from '@salesforce/apex/QuotaService.getQuota';
import getNextQuota from '@salesforce/apex/QuotaService.getNextQuota';
import getPreviousQuota from '@salesforce/apex/QuotaService.getPreviousQuota';
import generalReferenceMC from '@salesforce/messageChannel/GeneralReferenceMessageChannel__c';

export default class QuotaView extends LightningElement {
    context = createMessageContext();
    salesQuota = '0';
    salesForecast = '0';
    salesActual = '0';
    periodLabel = 'Sales Quotas for ???'
    periodId = '';    
    showSpinner = false;
    salesForecastStyle = '';
    salesActualStyle = '';
    generalReferenceSubscription = null;
    startDate;
    endDate;

    constructor() {
        super();

        this.showSpinner = true;

        getQuota({})
        .then(theResponse => {
            this.salesQuota = theResponse.salesQuota;
            this.salesForecast = theResponse.salesForecast;
            this.salesActual = theResponse.salesActual;
            this.periodLabel = 'Sales Quotas for ' + theResponse.periodLabel;
            this.periodId = theResponse.periodId;
            this.startDate = theResponse.startDate;
            this.endDate = theResponse.endDate;
            this.sendPeriodRefMessage(theResponse.periodId, theResponse.startDate, theResponse.endDate);
            this.setStyles();
            this.showSpinner = false;          
        });

        this.generalReferenceSubscription = subscribe(
            this.context,
            generalReferenceMC,
            message => {
                this.receiveQueryMessage( message );
            }
        );          
    }

    receiveQueryMessage ( message ) {
        if (message.recordData.queryType === 'PeriodReference') {
            this.sendPeriodRefMessage(this.periodId, this.startDate, this.endDate);
        }
    }

    next(event) {
        this.showSpinner = true;

        getNextQuota({periodId: this.periodId})
        .then(theResponse => {
            this.salesQuota = theResponse.salesQuota;
            this.salesForecast = theResponse.salesForecast;
            this.salesActual = theResponse.salesActual;
            this.periodLabel = 'Sales Quotas for ' + theResponse.periodLabel;
            this.periodId = theResponse.periodId;
            this.startDate = theResponse.startDate;
            this.endDate = theResponse.endDate;
            this.sendPeriodRefMessage(theResponse.periodId, theResponse.startDate, theResponse.endDate);
            this.setStyles();
            this.showSpinner = false;
        });
    }
    previous(event) {
        this.showSpinner = true;

        getPreviousQuota({periodId: this.periodId})
        .then(theResponse => {
            this.salesQuota = theResponse.salesQuota;
            this.salesForecast = theResponse.salesForecast;
            this.salesActual = theResponse.salesActual;
            this.periodLabel = 'Sales Quotas for ' + theResponse.periodLabel;
            this.periodId = theResponse.periodId;
            this.startDate = theResponse.startDate;
            this.endDate = theResponse.endDate;            
            this.sendPeriodRefMessage(theResponse.periodId, theResponse.startDate, theResponse.endDate);
            this.setStyles();
            this.showSpinner = false;
        });
    }
    sendPeriodRefMessage(periodId, startDate, endDate) {
        const message = {
             recordId: periodId,
             message : 'Period Has Changed',
             source: 'quotaView.lwc',
             recordData : { startDate: startDate, endDate: endDate}    
        };

        publish (this.context, periodRefMC, message);
    }
    disconnectedCallback() {
        releaseMessageContext(this.context);
    }   
    setStyles() {
        const sq = parseInt(this.salesQuota.replace(',',''));
        const sa = parseInt(this.salesActual.replace(',',''));
        const hlimit = sq / 2;
        const sf = parseInt(this.salesForecast.replace(',',''));
        this.salesActualStyle = 'margin-left:15px;';
        this.salesForecastStyle = 'margin-left:20px;';

        if (sq > sa) {
            if (sa < hlimit) {
                this.salesActualStyle += 'background-color:red';
            } else 
            {
                this.salesActualStyle += 'background-color:yellow';
            }
        } else {
            this.salesActualStyle += 'background-color:limegreen'; 
        }

        if (sq > sf) {
            if (sf < hlimit) {
                this.salesForecastStyle += 'background-color:red';
            } else 
            {
                this.salesForecastStyle += 'background-color:yellow';
            }
        } else {
            this.salesForecastStyle += 'background-color:limegreen'; 
        }  
    } 
}