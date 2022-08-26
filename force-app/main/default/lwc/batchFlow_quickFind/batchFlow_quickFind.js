import { LightningElement, api } from 'lwc';

export default class BatchFlow_quickFind extends LightningElement {
    @api flowSchedules = [];
    handleViewFlow(event) {
        console.log(event.currentTarget.dataset.value)
        const detail = event.currentTarget.dataset.value
        const viewFlowEvent = new CustomEvent("viewflow", { detail: detail });
        this.dispatchEvent(viewFlowEvent);
    }
}