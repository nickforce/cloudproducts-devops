import { LightningElement } from 'lwc';

export default class BatchFlow_pageHeader extends LightningElement {
    handleNewSch() {
        console.log('event send')
        this.dispatchEvent(new CustomEvent('loading'));
    }
}