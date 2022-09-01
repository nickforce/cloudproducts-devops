import { LightningElement, api } from 'lwc';

export default class BatchFlow_monitorFlow extends LightningElement {
    @api flowSchedule
    connectedCallback() {
        
    }
    handleViewFlow(event) {
        //console.log(event.currentTarget.dataset.value)
        const detail = event.currentTarget.dataset.value
        const viewFlowEvent = new CustomEvent("viewflow", { detail: detail });
        this.dispatchEvent(viewFlowEvent);
    }
    handleDeleteFlow(event) {
        //console.log(event.currentTarget.dataset.value)
        const detail = event.currentTarget.dataset.value
        const deleteFlowEvent = new CustomEvent("deleteflow", { detail: detail });
        this.dispatchEvent(deleteFlowEvent);
        //console.log('deleteflow event sent')
    }
}