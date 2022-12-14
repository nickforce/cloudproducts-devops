import getBatchFlowSchedules from '@salesforce/apex/BatchFlowDataService.getBatchFlowSchedules'
import noHeader from '@salesforce/resourceUrl/noHeader';
import { refreshApex } from '@salesforce/apex';
import { getRecord, updateRecord, createRecord, getFieldValue, deleteRecord } from 'lightning/uiRecordApi';
import Batch_Flow_Sch__c from '@salesforce/schema/Batch_Flow_Sch__c';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import { LightningElement, api, track, wire } from 'lwc';
import querySelectedBatchFlowSch from '@salesforce/apex/BatchFlowDataService.querySelectedBatchFlowSch'

export default class BatchFlow extends LightningElement {
    @track flowSchForm = {}
    @api flowId = ''
    flowSch = {}
    @track newBatchFlowSchName = ''
    @track newBatchFlowSchStartDate = ''
    @track newBatchFlowSchEndDate = ''
    @track newBatchFlowSchPreferredStartTime
    @track editFlowSchId = ''
    @track queryFlowSch = {}
    @track modalState = 'Create'

    @track strMessage = '';
    @api selectedBatchFlowSchId
    connectedCallback() {
        loadStyle(this, noHeader)
            .then(result => {})
    }
    
    play() {
        this.modalState = 'Create'
        const player = this.template.querySelector('c-modal');
        //console.log('play')
        // the player might not be in the DOM just yet
        if (player) {
            this.flowSchForm = {}
            //console.log('play found')
            player.show();
        }
    }
    async playEdit() {
        this.modalState = 'Edit'
        const player = this.template.querySelector('c-modal');
        console.log('play')
        // the player might not be in the DOM just yet
        if (player) {
            
            
            this.flowSchForm = {}
            await this.handleQuerySelectedBatchFlowSch();
            player.show();
            //console.log('play found')
        }
    }
    async handleQuerySelectedBatchFlowSch() {
        const selectedBatchFlowSch = {
            Id: this.editFlowSchId
        }
        if(selectedBatchFlowSch) {
            querySelectedBatchFlowSch({data: selectedBatchFlowSch})
             .then(result => {
                console.log('query result ' + JSON.stringify(result))
                // console.log(result.data.fields.Name)
                // console.log(result[0].Name)
                this.queryFlowSch = result
                // this.queryFlowSch = result.map(type => {
                //     return {
                //         Name: type.Name
                //     }
                // })
                //this.queryFlowSch.Name = result.Name
                
                this.flowSchForm = result // remove this because api names?
                this.newBatchFlowSchName = this.flowSchForm.Name
                this.newBatchFlowSchStartDate = this.flowSchForm.Start_Date__c
                this.newBatchFlowSchEndDate = this.flowSchForm.End_Date__c
                this.newBatchFlowSchPreferredStartTime = this.msToTime(this.flowSchForm.Preferred_Start_Time__c)
                this.showOnDayOptions = false
                this.selectedFrequencyOption = this.flowSchForm.Frequency__c
                if(this.selectedFrequencyOption === 'Monthly') {
                    this.showOnDayOptions = true
                }
                //this.flowSchForm.frequency = this.selectedFrequencyOption
                this.selectedDayOfMonth = this.flowSchForm.Day_of_Month__c
                //this.flowSchForm.dayOfMonth = this.selectedDayOfMonth
                
                //console.log('parse 8888888' + this.selectedDayOfMonth)
                //console.log('parse 8888888' + this.newBatchFlowSchStartDate)
             })
             .catch(error => {
                console.log('query error: ',error);
             })
             .finally(() => {
                // this.queryFlowSch = data
                //console.log('2')
                console.log('finally,query result ' + this.queryFlowSch)
             })
        }
    }

    closeModal() {
        const player = this.template.querySelector('c-modal');
        //console.log('play')
        // the player might not be in the DOM just yet
        if (player) {
            this.flowSchForm = {}
            //console.log('play found')
            player.hide();
        }
    }

    msToTime(s) {
        /*
        Divide the milliseconds by 1000 to get the seconds.
        Divide the seconds by 60 to get the minutes.
        Divide the minutes by 60 to get the hours.
        Add a leading zero if the values are less than 10 to format them consistently.
        */
        let seconds = s / 1000
        let minutes = seconds / 60
        let hours = minutes / 60
        console.log('hours ' + hours)
        let fHours = ''
        let fMinutes = '00'
        if(String(hours).includes('.')) {
            fHours = String(hours).substring(0, String(hours).indexOf('.'))
            // if(fHours>12) {
            //     fHours = fHours - 12
            // }
            // else if(fHours==='0') {
            //     fHours = 12
            // }
            if(fHours==='0') {
                fHours = '00'
            }
            fMinutes = 60*(String(hours).substring(String(hours).indexOf('.'), String(hours).length))
        }
        else {
            fHours = String(hours)
            if(fHours==='0') {
                fHours = '00'
            }
            // if(fHours>12) {
            //     fHours = fHours - 12
            // }
            // else if(fHours==='0') {
            //     fHours = 12
            // }
            console.log(fHours)
        }

        //let ampm = hours > 12 ? ' PM' : ' AM'
        //return fHours + ':' + fMinutes + ampm
        return fHours + ':' + fMinutes + ':00.000'
    }

    
    @track showSchedule = false
    handleToggleSchedule() {
        this.showSchedule = true;
    }
    handleSaveSchedule() {
        this.showSchedule = false;
    }
    handleLoading() {
        //console.log('event here')
        //this.showSchedule = true;
        this.play()
    }
    handleEditFlow(evt) {
        console.log('event edit-flow' + evt.detail)
        console.log(JSON.stringify(evt.detail))
        this.editFlowSchId = evt.detail
        
        this.playEdit()
    }
    handleScheduling() {
        //console.log('handleScheduling event here')
        this.refreshSchedules()
        this.showSchedule = false;
        
    }
    handleDoneLoading() {
        this.isLoading = false;
    }
    refreshSchedules() {
        
        refreshApex(this.refreshTable)
    }
    @track selectedFlow;
    isLoading = false;
    handleViewFlow(evt) { // async 
        this.isLoading = true;
        this.showSchedule = true;
        this.selectedFlow = evt.detail;
        //console.log('44444444444444444')
        //console.log(JSON.stringify(evt.detail))
        //console.log('handleViewFlow' + this.selectedFlow);

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
    @track selectedFrequencyOption = ''
    @track frequencyOptions = [
        {'label': 'Daily', 'value': 'Daily'},
        {'label': 'Monthly', 'value': 'Monthly'}
    ]
    
    @track selectedDayOfMonth = ''
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
    }
    handleDayOfMonthOptionChange(event) {
        
        this.selectedDayOfMonth = event.detail.value;
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

        // let flowSchForm = this.flowSchForm;
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
        // const fields = {
        //     Name: flowSchForm.name,
        //     Frequency__c: flowSchForm.frequency,
        //     Day_of_Month__c: flowSchForm.dayOfMonth,
        //     Start_Date__c: flowSchForm.startDate,
        //     End_Date__c: flowSchForm.endDate,
        //     Preferred_Start_Time__c: flowSchForm.preferredStartTime
        // }

        const fields = {
            Name: this.newBatchFlowSchName,
            Frequency__c: this.selectedFrequencyOption,
            Day_of_Month__c: this.selectedDayOfMonth,
            Start_Date__c: this.newBatchFlowSchStartDate,
            End_Date__c: this.newBatchFlowSchEndDate,
            Preferred_Start_Time__c: this.newBatchFlowSchPreferredStartTime,
        }

        if(this.editFlowSchId != '') {
            fields.Id = this.editFlowSchId
        }

        const createRecordInput = { 
            apiName: Batch_Flow_Sch__c.objectApiName, 
            fields 
        };

        const updateRecordInput = { 
            fields,
        };

        updateRecord(updateRecordInput)
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
            console.log('upsertRecord error: ',error);
        });
    }
    handleNewBatchFlowSchNameChange(event) {
        this.newBatchFlowSchName = event.detail.value
        
    }
    handlePreferredStartTimeChange(event) {
        
        this.newBatchFlowSchPreferredStartTime = event.detail.value
    }
    
    handleStartDateChange(event) {
        this.newBatchFlowSchStartDate = event.detail.value

    }
    handleEndDateChange(event) {
        
        this.newBatchFlowSchEndDate = event.detail.value
    }
}