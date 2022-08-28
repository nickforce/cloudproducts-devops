import getBatchFlowSchedules from '@salesforce/apex/BatchFlowDataService.getBatchFlowSchedules'
import noHeader from '@salesforce/resourceUrl/noHeader';
import { refreshApex } from '@salesforce/apex';
import { getRecord, createRecord, getFieldValue, deleteRecord } from 'lightning/uiRecordApi';
import Batch_Flow_Sch__c from '@salesforce/schema/Batch_Flow_Sch__c';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import { LightningElement, api, track, wire } from 'lwc';

export default class BatchFlow extends LightningElement {
    @track flowSchForm = {}
    @api flowId = ''
    flowSch = {}
    newBatchFlowSchName = ''

    @track strMessage = '';
    @api selectedBatchFlowSchId
    connectedCallback() {
        loadStyle(this, noHeader)
            .then(result => {})
    }
    
    play() {
        const player = this.template.querySelector('c-modal');
        console.log('play')
        // the player might not be in the DOM just yet
        if (player) {
            this.flowSchForm = {}
            console.log('play found')
            player.show();
        }
    }

    closeModal() {
        const player = this.template.querySelector('c-modal');
        console.log('play')
        // the player might not be in the DOM just yet
        if (player) {
            this.flowSchForm = {}
            console.log('play found')
            player.hide();
        }
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
        //this.showSchedule = true;
        this.play()
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

    showOnDayOptions = false
    selectedFrequencyOption = ''
    @track frequencyOptions = [
        {'label': 'Daily', 'value': 'Daily'},
        {'label': 'Monthly', 'value': 'Monthly'}
    ]
    
    selectedDayOfMonth = ''
    @track daysOfMonth = [
        {label: '1', value: '1'},
        {label: '2', value: '2'},
        {label: '3', value: '3'},
        {label: '4', value: '4'},
        {label: '5', value: '5'},
        {label: '6', value: '6'},
        {label: '7', value: '7'},
        {label: '8', value: '8'},
        {label: '9', value: '9'},
        {label: '10', value: '10'},
        {label: '11', value: '11'},
        {label: '12', value: '12'},
        {label: '13', value: '13'},
        {label: '14', value: '14'},
        {label: '15', value: '15'},
        {label: '16', value: '16'},
        {label: '17', value: '17'},
        {label: '18', value: '18'},
        {label: '19', value: '19'},
        {label: '20', value: '20'},
        {label: '21', value: '21'},
        {label: '22', value: '22'},
        {label: '23', value: '23'},
        {label: '24', value: '24'},
        {label: '25', value: '25'},
        {label: '26', value: '26'},
        {label: '27', value: '27'},
        {label: '28', value: '28'},
        {label: 'last', value: 'last'}
    ]
    handleFrequencyOptionChange(event) {
        this.showOnDayOptions = false
        this.selectedFrequencyOption = event.detail.value;
        if(this.selectedFrequencyOption === 'Monthly') {
            this.showOnDayOptions = true
        }
        this.flowSchForm.frequency = this.selectedFrequencyOption
    }
    handleDayOfMonthOptionChange(event) {
        this.selectedDayOfMonth = event.detail.value;
        this.flowSchForm.dayOfMonth = this.selectedDayOfMonth
    }

    handleSaveBatchFlowSch(){
        // this.isLoading = true;

        const isRequiredValFilledInForm = [...this.template.querySelectorAll('lightning-input')]
                                        .reduce((validSoFar, inputCmp) => {
                                            console.log('inputCmp: ',inputCmp);
                                            console.log('inputCmp JSON: ',JSON.stringify(inputCmp));
                                            inputCmp.reportValidity();
                                            return validSoFar && inputCmp.checkValidity();
                                        }, true);

        let flowSchForm = this.flowSchForm;
        // form validation here
        //
        if(isRequiredValFilledInForm){
            this.upsertBatchFlowSchForm();
            // additional method here.. 
            
        }else{
            // this.isLoading = false;
        }
    }

    async upsertBatchFlowSchForm() {

        let flowSchForm = this.flowSchForm;
        const fields = {
            //Id: this.flowId,
            Name: flowSchForm.name,
            Frequency__c: flowSchForm.frequency,
            Day_of_Month__c: flowSchForm.dayOfMonth,
            Start_Date__c: flowSchForm.startDate,
            End_Date__c: flowSchForm.endDate,
            Preferred_Start_Time__c: flowSchForm.preferredStartTime
        }

        const recordInput = { 
            apiName: Batch_Flow_Sch__c.objectApiName, 
            fields 
        };

        createRecord(recordInput)
        .then(result => {
            this.flowSch = result;
            this.dispatchEvent(new CustomEvent('scheduling'));
            // Clear form?
            // render different view or template
            // this.isLoading = false;
            //this.refreshSchedules()
            this.closeModal()

        })
        .catch(error => {
            this.isLoading = false;
            console.log('createRecord error: ',error);
        });
    }
    handleNewBatchFlowSchNameChange(event) {
        this.newBatchFlowSchName = event.detail.value
        this.flowSchForm.name = this.newBatchFlowSchName
    }
    handlePreferredStartTimeChange(event) {
        this.flowSchForm.preferredStartTime = event.detail.value
    }
    handleStartDateChange(event) {
        console.log('handleStartDateChange')
        this.flowSchForm.startDate = event.detail.value
    }
    handleEndDateChange(event) {
        this.flowSchForm.endDate = event.detail.value
    }
}