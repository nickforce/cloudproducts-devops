import { LightningElement, api, track } from 'lwc';
import querySelectedBatchFlowSch from '@salesforce/apex/BatchFlowDataService.querySelectedBatchFlowSch'

export default class BatchFlow_viewFlowSchedule extends LightningElement {
    @api flowSchedule = ''
    @track queryFlowSch

    connectedCallback() {
        console.log(JSON.stringify(this.flowSchedule))
        console.log('scheduleFlow' + this.flowSchedule.Name)
        //
        setTimeout(() => {
            console.log('scheduleFlow' + this.flowSchedule)
            if(this.flowSchedule) {
                this.handleQuerySelectedBatchFlowSch();
            }
            this.dispatchEvent(new CustomEvent('doneloading'));
        }, 2000);
    }
    
    handleDeleteFlow(event) {
        console.log(event.currentTarget.dataset.value)
        const detail = event.currentTarget.dataset.value
        const deleteFlowEvent = new CustomEvent("deleteflow", { detail: detail });
        this.dispatchEvent(deleteFlowEvent);
        console.log('deleteflow event sent')
    }

    async handleQuerySelectedBatchFlowSch() {
        const selectedBatchFlowSch = {
            Id: this.flowSchedule
        }
        if(selectedBatchFlowSch) {
            querySelectedBatchFlowSch({data: selectedBatchFlowSch})
             .then(result => {
                console.log(JSON.stringify(result))
                console.log(result.data.fields.Name)
                console.log(result[0].Name)
                this.queryFlowSch = result.map(type => {
                    return {
                        Name: type.Name
                    }
                })
             })
             .catch(error => {

             })
             .finally(() => {
                // this.queryFlowSch = data
                console.log('2')
                console.log(this.queryFlowSch)
             })
        }
    }
}