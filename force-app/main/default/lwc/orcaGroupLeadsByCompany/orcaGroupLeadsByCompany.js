import { LightningElement, wire, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

import getDataToDisplayActivity from '@salesforce/apex/CompanyLeadsComponentController.getDataToDisplayActivity';

export default class OrcaGroupLeadsByCompany extends NavigationMixin(LightningElement) {
    @api recordId;
    @api fieldsToDisplay;
    @track leadListWrapper = [];


    connectedCallback() {
        console.log('RecordId:: ' + this.recordId);
        console.log('fieldsToDisplay:: ' + this.fieldsToDisplay);
    }

    @wire(getDataToDisplayActivity, { leadId: '$recordId', fieldsToDisplay: '$fieldsToDisplay' })
    wiredLeadData({ error, data }) {
        if(data){
            if(data.length > 0){
                this.leadListWrapper = data;
            } else {
                this.leadListWrapper = null;
            }
            console.log('OrcaGroupLeadsByCompany Data:: ' +  this.leadListWrapper);
            console.log('OrcaGroupLeadsByCompany Stringify Data:: ' +  JSON.stringify(this.leadListWrapper));
        } else {
            this.leadListWrapper = [];
            console.log('OrcaGroupLeadsByCompany Error:: ' + JSON.stringify(error));
        }
    }

    navigateToLeadRecordPage(event) {
        const leadId = event.currentTarget.getAttribute('lead-id');
        console.log(leadId);
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: leadId,
                objectApiName: 'Lead',
                actionName: 'view'
            }
        });
    }
}