import { LightningElement, track, api, wire } from 'lwc';
import { getRecord, createRecord, getFieldValue } from 'lightning/uiRecordApi';
import Batch_Flow_Sch__c from '@salesforce/schema/Batch_Flow_Sch__c';
import upsertBatchFlowSch from '@salesforce/apex/BatchFlowDataService.upsertBatchFlowSch'
import querySelectedBatchFlowSch from '@salesforce/apex/BatchFlowDataService.querySelectedBatchFlowSch'


export default class BatchFlow_scheduleFlow extends LightningElement {
    @track flowSchForm = {}
    @api flowId = ''
    flowSch = {}
    newBatchFlowSchName = ''
    
    @track queryFlowSch

    connectedCallback() {
        setTimeout(() => {
            console.log('scheduleFlow' + this.flowId)
            if(this.flowId) {
                this.handleQuerySelectedBatchFlowSch();
            }
            this.dispatchEvent(new CustomEvent('doneloading'));
        }, 2000);
    }

    handleNewBatchFlowSchNameChange(event) {
        this.newBatchFlowSchName = event.detail.value
        this.flowSchForm.name = this.newBatchFlowSchName
    }
    handlePreferredStartTimeChange(event) {
        this.flowSchForm.preferredStartTime = event.detail.value
    }
    handleStartDateChange(event) {
        this.flowSchForm.startDate = event.detail.value
    }
    handleEndDateChange(event) {
        this.flowSchForm.endDate = event.detail.value
    }
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

    

    // async editFlowQueryRecord() {
    //     const fields = [
    //         'Batch_Flow_Sch__c.Name',
    //         'Batch_Flow_Sch__c.Frequency'
    //     ]
    //     getRecord
    // }
    
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
        })
        .catch(error => {
            this.isLoading = false;
            console.log('createRecord error: ',error);
        });
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

    async handleQuerySelectedBatchFlowSch() {
        const selectedBatchFlowSch = {
            Id: this.flowId
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

    /*
    handleSaveBatchFlowSch() {
        const selectedBatchFlowSch = {
            Name: 'Quarterly Billing Sync'
        }
        console.log('handle save flow sch')
        this.dispatchEvent(new CustomEvent('scheduling'));
        // console.log(this.selectedBatchApexClass)
        // console.log(this.selectedScope)
        if(selectedBatchFlowSch) {
            upsertBatchFlowSch({data: selectedBatchFlowSch})
            .then(() => {
                // dispatch toast
                // requery
            })
            .catch(error => {
                // dispatch toast event
            })
            .finally(() => {
                // turn loading off
                console.log('event send')
                
            })
        }
    }
    */
}