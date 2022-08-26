import { LightningElement, track, wire, api } from 'lwc';

import getBatchApexClasses from '@salesforce/apex/BatchFlowDataService.getBatchApexClasses'
import upsertBatchFlow from '@salesforce/apex/BatchFlowDataService.upsertBatchFlow'
export default class BatchFlow_jobGroup extends LightningElement {
    @api groupId;
    @api editBatchFlowId;
    @track newJobForm = false;

    isExpanded = false;

    setExpanded(event){
        this.isExpanded = !this.isExpanded ;
    }

    @track items = [
        {
            type: 'icon',
            label: 'My Pill',
            name: 'mypill',
            iconName: 'standard:account',
            alternativeText: 'Account',
        },
        {
            type: 'avatar',
            label: 'Avatar Pill',
            name: 'avatarpill',
            src: '/my/path/avatar.jpg',
            fallbackIconName: 'standard:user',
            variant: 'circle',
            alternativeText: 'User avatar',
        },
        {
            type: 'icon',
            label: 'Icon Pill',
            name: 'iconpill',
            iconName: 'standard:account',
            alternativeText: 'Account',
        },
        {
            type: 'icon',
            label: 'Icon Pill',
            name: 'iconpill',
            iconName: 'standard:account',
            alternativeText: 'Account',
        },
        {
            type: 'icon',
            label: 'Icon Pill',
            name: 'iconpill',
            iconName: 'standard:account',
            alternativeText: 'Account',
        },
        {
            type: 'icon',
            label: 'Icon Pill',
            name: 'iconpill',
            iconName: 'standard:account',
            alternativeText: 'Account',
        },
        {
            type: 'icon',
            label: 'Icon Pill',
            name: 'iconpill',
            iconName: 'standard:account',
            alternativeText: 'Account',
        },
        {
            type: 'icon',
            label: 'Icon Pill',
            name: 'iconpill',
            iconName: 'standard:account',
            alternativeText: 'Account',
        },
    ];


    handleNewJob() {
        this.newJobForm = true;
    }
    
    handleCancelNewJob() {
        this.newJobForm = false;
    }

    handleSaveJob() {
        const selectedJob = {
            Batch_Flow_Group__c: this.groupId,
            Apex_Class__c: 'TestJob',
            Scope_Size__c: 200
        }
        console.log('handle save job')
        console.log(this.selectedBatchApexClass)
        console.log(this.selectedScope)
        if(selectedJob) {
            upsertBatchFlow({data: selectedJob})
            .then(() => {
                // dispatch toast
                // requery
            })
            .catch(error => {
                // dispatch toast event
            })
            .finally(() => {
                // turn loading off
            })
        }
    }

    handleJobSelect(event) {
        // retrieve the selected job
        // set 
    }

    setBatchApexClass(event){
        // let guestObj = this.guestsList.find(ele => event.target.dataset.id === ele.name);
        // guestObj.lastName = event.target.value;
        // console.log('setMemberLn: ' + JSON.stringify(guestObj));
        if(event.target.value) {
            this.selectedBatchApexClass = event.target.value
        }
    }

    handleChangeScope(event) {
        this.selectedScope = event.detail.value
    }

    selectedBatchApexClass = ''
    selectedScope = 200

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
            this.apexClassOptions.unshift({ label: 'Select apex class..', value: '' })
        } else if (error) {
            this.apexClassOptions = undefined
            this.error = error
        }
    }
}