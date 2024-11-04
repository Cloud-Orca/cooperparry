import { LightningElement, wire, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

import getDataToDisplayActivity from '@salesforce/apex/LeadActivityMatchedController.getDataToDisplayActivity';
export default class OrcaLeadActivityMatched extends NavigationMixin(LightningElement) {
    @api recordId;
    @track activityWrapperList = [];
    section = '';

    connectedCallback() {
        console.log('RecordId:: ' + this.recordId);
    }

    @wire(getDataToDisplayActivity, { leadId: '$recordId' })
    wiredLeadData({ error, data }) {
        if(data){
            if(data.length > 0){
                this.activityWrapperList = data;
            } else {
                this.activityWrapperList = null;
            }
            console.log('OrcaLeadActivityMatched Data:: ' +  this.activityWrapperList);
            console.log('OrcaLeadActivityMatched Stringify Data:: ' +  JSON.stringify(this.activityWrapperList));
        } else {
            this.activityWrapperList = [];
            console.log('OrcaLeadActivityMatched Error:: ' + JSON.stringify(error));
        }
    }

    handleSectionToggle(event) {
        const openSections = event.detail.openSections;
        console.log('OrcaLeadActivityMatched openSections:: ' + openSections);
    }

    handleUserClick(event){
        const userId = event.currentTarget.getAttribute('user-id');
        console.log('OrcaLeadActivityMatched userId:: ' + userId);

        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: userId,
                objectApiName: 'User',
                actionName: 'view'
            }
        }).then(url => {
            window.open(url, "_blank");
        });
    }

    handleLeadClick(event){
        const leadId = event.currentTarget.getAttribute('lead-id');
        console.log('OrcaLeadActivityMatched leadId:: ' + leadId);

        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: leadId,
                objectApiName: 'Lead',
                actionName: 'view'
            }
        }).then(url => {
            window.open(url, "_blank");
        });
    }
}