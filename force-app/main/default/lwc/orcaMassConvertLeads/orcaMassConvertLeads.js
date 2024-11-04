import { LightningElement, api, track, wire } from 'lwc';
//import { CurrentPageReference } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadStyle } from "lightning/platformResourceLoader";
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { refreshApex } from '@salesforce/apex';

import modal from "@salesforce/resourceUrl/custommodalcss";

import getDataToDisplayActivity from '@salesforce/apex/MassConvertLeadsController.getDataToDisplayActivity';
import massConvertLeads from '@salesforce/apex/MassConvertLeadsController.massConvertLeads';
//import updateMassConvertLeads from '@salesforce/apex/MassConvertLeadsController.updateMassConvertLeads';

import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import OPPORTUNITY_OBJECT from '@salesforce/schema/Opportunity';

export default class OrcaMassConvertLeads extends NavigationMixin(LightningElement) {
    @api recordId;
    @track leadListWrapper = [];
    @track primaryLead = [];
    @track leadsToConvert = [];
    @track accRecordTypeOptions = [];
    @track oppRecordTypeOptions = [];

    @track accSelectedRecordType = null;
    @track oppSelectedRecordType = null;
    @track searchedAccountToUpdate = null;
    @track searchedOppToUpdate = null;

    @track disableButton = true;
    @track createNewAccount = false;
    @track createNewOpportunity = false;
    @track isSearchAccount = false;
    @track isSearchOpportunity = false;
    @track accHasRecordTypes = false;
    @track oppHasRecordTypes = false;
    @track conHasRecordTypes = false;
    @track isLoading = false;

    accValue = 'createAcc';
    get accOptions() {
        return [
            { label: 'Create New Account', value: 'createAcc' },
            { label: 'Search Existing Account', value: 'searchAcc' },
        ];
    }

    oppValue = 'doNotCreateOpp';
    get oppOptions() {
        return [
            { label: 'Do not Create Opportunity', value: 'doNotCreateOpp' },
            { label: 'Create New Opportunity', value: 'createOpp' },
            { label: 'Search Existing Opportunity', value: 'searchOpp' },
        ];
    }

    connectedCallback() {
        loadStyle(this, modal);
        this.createNewAccount = true;
        this.createNewOpportunity = false;
        window.clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(() => {
            console.log('OrcaMassConvertLeads RecordId:: ' + this.recordId);
        }, 0);
    }

    // @wire(CurrentPageReference)
    // getStateParameters(currentPageReference) {
    //     if (currentPageReference) {
    //         this.recordId = currentPageReference.state.recordId;
    //     }
    //     console.log('OrcaMassConvertLeads RecordId:: ' + this.recordId);
    // }

    @wire(getDataToDisplayActivity, { leadId: '$recordId' })
    wiredLeadData({ error, data }) {
        if(data){
            //this.leadListWrapper = data;
            let leadList = [];

            data.forEach(lead => {
                leadList.push({
                    LeadId : lead.Id,
                    LeadName : lead.Name,
                    LeadCompany : lead.Company,
                    importId : {
                        ids : {
                            convertId : 'convert-' + lead.Id,
                            primaryId : 'primary-' + lead.Id
                        }
                    }
                })
            });

            this.leadListWrapper = leadList;
            // console.log('OrcaMassConvertLeads leadList:: ' +  leadList);
            // console.log('OrcaMassConvertLeads Data:: ' +  this.leadListWrapper);
            // console.log('OrcaMassConvertLeads Stringify Data:: ' +  JSON.stringify(this.leadListWrapper));
        } else if(error){
            this.leadListWrapper = undefined;
            console.log('OrcaMassConvertLeads Error:: ' + JSON.stringify(error));
        }
    }

    @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
    accountInfo({ error, data }) {
        if (data) {
            const recordTypeInfos = Object.values(data.recordTypeInfos);
            const recordTypes = recordTypeInfos.filter(recordType => recordType.name !== 'Master');
            this.accRecordTypeOptions = recordTypes.map(recordType => ({
                label: recordType.name,
                value: recordType.recordTypeId
            }));
            this.accHasRecordTypes = this.accRecordTypeOptions.length > 0;
        } else if (error) {
            this.showToast('Error!', 'An error has occured. Error: '+ error.body.message, 'error', 'dismissable');
        }
    }

    @wire(getObjectInfo, { objectApiName: OPPORTUNITY_OBJECT })
    opportunityInfo({ error, data }) {
        if (data) {
            const recordTypeInfos = Object.values(data.recordTypeInfos);
            const recordTypes = recordTypeInfos.filter(recordType => recordType.name !== 'Master');
            this.oppRecordTypeOptions = recordTypes.map(recordType => ({
                label: recordType.name,
                value: recordType.recordTypeId
            }));
            this.oppHasRecordTypes = this.oppRecordTypeOptions.length > 0;
        } else if (error) {
            this.showToast('Error!', 'An error has occured. Error: '+ error.body.message, 'error', 'dismissable');
        }
    }

    onChangeConvert(event){
        let selectedLeadToConvert = event.target.value;

        if(event.target.checked){     
            if(!this.leadsToConvert.includes(selectedLeadToConvert)){
                this.leadsToConvert.push(selectedLeadToConvert);
            }
        } else {
            let index = this.leadsToConvert.indexOf(selectedLeadToConvert);

            if(index !== -1){
                this.leadsToConvert.splice(index, 1);
            }
        }
        // console.log('OrcaMassConvertLeads LeadsToConvert:: ' + this.leadsToConvert);

        this.checkButtonState();
    }

    onChangePrimary(event){
        let selectedPrimaryLead = event.target.value;
        this.primaryLead = selectedPrimaryLead;

        // if(event.target.checked){
        //     if (this.primaryLead.length === 1) {
        //         event.target.checked = false;
        //         this.showToast('Error!', 'Only one primary lead can be selected. ', 'error', 'dismissable');
        //     } else {
        //         if(!this.primaryLead.includes(selectedPrimaryLead)){
        //             this.primaryLead.push(selectedPrimaryLead);
        //         }
        //     }

        // } else {
        //     const index = this.primaryLead.indexOf(selectedPrimaryLead);
        //     if(index !== -1){
        //         this.primaryLead.splice(index, 1);
        //     }   
        // }

        // console.log('OrcaMassConvertLeads PrimaryLead:: ' + this.primaryLead);
        this.checkButtonState();
    }

    handleSelectedAccOption(event){
        if(event.detail.value == 'createAcc'){
            this.createNewAccount = true;
            this.isSearchAccount = false;
        }

        if(event.detail.value == 'searchAcc'){
            this.createNewAccount = false;
            this.isSearchAccount = true
        } else {
            this.isSearchAccount = false;
        }
    }

    handleSelectedOppOption(event) {
        if(event.detail.value == 'doNotCreateOpp'){
            this.createNewOpportunity = false;
            this.isSearchOpportunity = false;
        }

        if(event.detail.value == 'createOpp'){
            this.createNewOpportunity = true;
            this.isSearchOpportunity = false;
        }

        if(event.detail.value == 'searchOpp'){
            this.createNewOpportunity = false;
            this.isSearchOpportunity = true;
        } else {
            this.isSearchOpportunity = false;
        }
    }

    handleAccRecordTypeChange(event){
        this.accSelectedRecordType = event.detail.value;
    }

    handleAccountSelection(event){
        this.searchedAccountToUpdate = event.currentTarget.value;
    }

    handleOppRecordTypeChange(event){
        this.oppSelectedRecordType = event.detail.value;
    }

    handleOppSelection(event){
        this.searchedOppToUpdate = event.currentTarget.value;
    }


    handleConvertButton(){
        this.isLoading = true;
        //let primaryLead = this.primaryLead[0];
        // console.log('OrcaMassConvertLeads LeadsToConvert:: ' + this.leadsToConvert);
        // console.log('OrcaMassConvertLeads PrimaryLead:: ' + this.primaryLead);
        // console.log('OrcaMassConvertLeads Searched Account Id:: ' + this.searchedAccountToUpdate);
        // console.log('OrcaMassConvertLeads Searched Opportunity Id?:: ' + this.searchedOppToUpdate);
        // console.log('OrcaMassConvertLeads Create New Opportunity?:: ' + this.createNewOpportunity);
        // console.log('OrcaMassConvertLeads Account Record Type:: ' + this.accSelectedRecordType);
        // console.log('OrcaMassConvertLeads Opportunity Record Type:: ' + this.oppSelectedRecordType);
        
        if(this.createNewAccount == true && this.accHasRecordTypes == true && this.accSelectedRecordType == null){
            this.isLoading = false;
            this.showToast('Error!', 'Please Select Account Record Type', 'error', 'dismissable');
        } else if(this.createNewOpportunity == true && this.oppHasRecordTypes == true && this.oppSelectedRecordType == null){
            this.isLoading = false;
            this.showToast('Error!', 'Please Select Opportunity Record Type', 'error', 'dismissable');
        } else if(this.leadsToConvert.length != 0){
            massConvertLeads({
                leadConvertIds: this.leadsToConvert,
                primaryLeadId: this.primaryLead,
                accountIdToUpdate: this.searchedAccountToUpdate,
                opportunityIdToUpdate: this.searchedOppToUpdate,
                createNewOpportunity: this.createNewOpportunity,
                accountRecordTypeId: this.accSelectedRecordType,
                opportunityRecordTypeId: this.oppSelectedRecordType
            })
            .then( result => {
                console.log(result);
                this.isLoading = false;
                if(result == 'Leads Successfully Converted'){
                    this.showToast('Success Message!', 'Successfully Converted Leads.', 'success', 'dismissable');
                    this.dispatchEvent(new CloseActionScreenEvent());
                    // location.reload();
                    window.location.href = "/" + this.recordId;
                    // console.log('OrcaMassConvertLeads massConvertLeads Result:: ' + result);
                }
                else{
                    this.showToast('Error!', 'An error has occured. Error: '+ result, 'error', 'dismissable');
                }
            })
            .catch( error => {
                this.isLoading = false;
                this.showToast('Error!', 'An error has occured. Error: '+ error.body.message, 'error', 'dismissable');
            });
        }


        // } else if(this.leadsToConvert.length != 0 && this.isSearchAccount == false && this.isSearchOpportunity == false){
        //     massConvertLeads({
        //         leadConvertIds: this.leadsToConvert,
        //         leadPrimaryId: this.primaryLead,
        //         recordTypeId: this.accSelectedRecordType,
        //         createNewOpportunity: this.createNewOpportunity
        //     })
        //     .then( result => {
        //         this.isLoading = false;
        //         if(result){
        //             this.showToast('Success Message!', 'Successfully Converted Leads.', 'success', 'dismissable');
        //             this.dispatchEvent(new CloseActionScreenEvent());
        //             console.log('OrcaMassConvertLeads massConvertLeads Result:: ' + result);
        //         }
        //     })
        //     .catch( error => {
        //         this.isLoading = false;
        //         this.showToast('Error!', 'An error has occured. Error: '+ error.body.message, 'error', 'dismissable');
        //     });
        // } else {
        //     updateMassConvertLeads({
        //         leadsToConvert: this.leadsToConvert,
        //         leadPrimaryId: primaryLead,
        //         accountIdToUpdate: this.searchedAccountToUpdate,
        //         opptyIdToUpdate: this.searchedOppToUpdate,
        //         createNewOpportunity: this.createNewOpportunity
        //     })
        //     .then( result => {
        //         this.isLoading = false;
        //         if(result){
        //             this.showToast('Success Message!', 'Successfully Converted Leads.', 'success', 'dismissable');
        //             this.dispatchEvent(new CloseActionScreenEvent());
        //             console.log('OrcaMassConvertLeads massConvertLeads Result:: ' + result);
        //         }
        //     })
        //     .catch( error => {
        //         this.isLoading = false;
        //         this.showToast('Error!', 'An error has occured. Error: '+ error.body.message, 'error', 'dismissable');
        //     });
        // }
    }

    handleCancelButton(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    // handleNavAccount(){
    //     this[NavigationMixin.GenerateUrl]({
    //         type: 'standard__recordPage',
    //         attributes: {
    //             recordId: this.existingAccountId,
    //             objectApiName: 'Account',
    //             actionName: 'view'
    //         }
    //     }).then(generatedUrl => {
    //         window.open(generatedUrl);
    //     });
    // }

    // handleNavOpportunity(){
    //     this[NavigationMixin.GenerateUrl]({
    //         type: 'standard__recordPage',
    //         attributes: {
    //             recordId: this.existingOppId,
    //             objectApiName: 'Opportunity',
    //             actionName: 'view'
    //         }
    //     }).then(generatedUrl => {
    //         window.open(generatedUrl);
    //     });
    // }

    checkButtonState(){
        this.disableButton = !(this.leadsToConvert.length > 0 && this.primaryLead.length > 0);
    }

    async showToast(title, message, variant, mode){
        const toastEvent = new ShowToastEvent({
            "title": title,
            "message": message,
            "variant": variant,
            "mode": mode
        });
        this.dispatchEvent(toastEvent);
    }
}