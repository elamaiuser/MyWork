import { LightningElement, api } from 'lwc';
import { uniqueId, orderBy } from 'c/lodash';
export default class SlwcCalendarLegend extends LightningElement {
    @api metadata = null;
    @api configData = null;

    get eventTypeSettings() {
        return this.configData && this.configData.eventTypeSettings ? this.configData.eventTypeSettings : [];
    }

    get objectTypes() {
        if(!this.metadata) return [];

        return this.metadata.filter(item => item.showLegend).map(item => {
            let eventTypes = this.eventTypeSettings.filter(eventType => {
                let isValid =  eventType.showLegend && eventType.objectType === item.objectType;
                //special cases
                if (item.objectType === 'availability') {
                    isValid = isValid && eventType.isAvailable === item.isAvailable;
                }
                return isValid;
            }).map(eventType => {
                return {
                    key: uniqueId(),
                    label: eventType.eventType,
                    style: [
                        `background-color: ${eventType.backgroundColor}`
                    ].join(';')   
                }
            })
            
            return {
                key: uniqueId(),
                label: item.label,
                showTemplateEntryIndicator: item.showTemplateEntryIndicator,
                eventTypes: orderBy(eventTypes, ['label'], ['asc'])
            };
        });
    };

    connectedCallback() {
        this.metadata = this.initMetadata(this.metadata)
        this.configData = this.initConfigData(this.configData)
        
        if (!this.initialized) {
            // this.gridData = this.processGridData(this._data) || {}
            this.initialized = true;
        }
    }

    renderedCallback() {
    }

    disconnectedCallback() {
    }

    initMetadata = (metadata) => {
        return metadata;
    }

    initConfigData = (configData) => {
        return configData;
    }
}