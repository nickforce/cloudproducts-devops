import { LightningElement, wire, track } from 'lwc';

import getBatchApexClasses from '@salesforce/apex/BatchFlowDataService.getBatchApexClasses'
export default class BatchFlow_newFlow extends LightningElement {
    
    
    selectedBatchApexClass = ''

    // private '
    error = undefined

    @track apexClassOptions = [];

    @wire(getBatchApexClasses)
    batchApexClasses({error,data}) {
        if(data) {
            this.apexClassOptions = data.map(type => {
                return {
                    label: type.Name,
                    value: type.Name
                }
            })
            this.apexClassOptions.unshift({ label: '- Batch Apex Classes -', value: '' })
        } else if (error) {
            this.apexClassOptions = undefined
            this.error = error
        }
    }


}