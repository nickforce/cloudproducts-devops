import getBatchFlowSchedules from '@salesforce/apex/BatchFlowDataService.getBatchFlowSchedules'
import noHeader from '@salesforce/resourceUrl/noHeader';
import { refreshApex } from '@salesforce/apex';
import { deleteRecord } from 'lightning/uiRecordApi';
import Batch_Flow_Sch__c from '@salesforce/schema/Batch_Flow_Sch__c';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import { LightningElement, api, track, wire } from 'lwc';

export default class BatchFlow extends LightningElement {
    @track strMessage = '';
    @api selectedBatchFlowSchId
    connectedCallback() {
        loadStyle(this, noHeader)
            .then(result => {})
    }
    @track showSchedule = false
    handleToggleSchedule() {
        this.showSchedule = true;
    }
    handleSaveSchedule() {
        this.showSchedule = false;
    }
    handleLoading() {
        console.log('event here')
        this.showSchedule = true;
    }
    handleScheduling() {
        console.log('handleScheduling event here')
        this.refreshSchedules()
        this.showSchedule = false;
        
    }
    handleDoneLoading() {
        this.isLoading = false;
    }
    refreshSchedules() {
        
        refreshApex(this.refreshTable)
    }
    selectedFlowId;
    isLoading = false;
    handleViewFlow(evt) { // async 
        this.isLoading = true;
        this.showSchedule = true;
        this.selectedFlowId = evt.detail;
        console.log('handleViewFlow' + this.selectedFlowId);

        // await this.loadBatchFlowSchedule();

        // this.isLoading = false;
    }

    loadBatchFlowSchedule() {

    }
    deleteSchId;
    
    handleDeleteFlow(event) {
        this.deleteSchId = event.detail
        this.deleteBatchFlowSchForm();
    }

    deleteBatchFlowSchForm() {
        let deleteBatchFlowScheduleId = this.deleteSchId;

        deleteRecord(deleteBatchFlowScheduleId)
            .then(result => {
                //
                this.refreshSchedules();
            })
            .catch(error => {
                this.isLoading = false;
                console.log('deleteRecord error: ',error);
            });
    }

    // private
    error = undefined
    @track flowSchs = [];
    refreshTable
    @wire(getBatchFlowSchedules)
    batchFlowSchedules(response) {
        this.refreshTable = response
        const { data, error } = response
        if(data) {
            // this.flowSchs = data.map(type => {
            //     return {
            //         type
            //     }
            // })
            this.flowSchs = data
        } else if (error) {
            this.flowSchs = undefined
            this.error = error
        }
    }
}