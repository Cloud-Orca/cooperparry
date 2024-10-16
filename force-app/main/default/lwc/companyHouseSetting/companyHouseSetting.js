import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCustomSettings from '@salesforce/apex/CompanyHouseSettingOfficer.getCustomSettings';
// import getProfileIds from '@salesforce/apex/CompanyHouseSettingOfficer.getProfileIds';
// import getProfileOptions from '@salesforce/apex/CompanyHouseSettingOfficer.getProfileOptions';
import saveCompanyHouseAPI from '@salesforce/apex/CompanyHouseSettingOfficer.saveCompanyHouseAPI';
import saveCompanyHouseSetting from '@salesforce/apex/CompanyHouseSettingOfficer.saveCompanyHouseSetting';

export default class CompanyHouseSetting extends LightningElement {
    isSpinner;
    companyHouseAPI;
    companyHouseSetting;
    batchOccurence;

    @track profileList;
    profileOptions;

    connectedCallback(){

        this.isSpinner = true;
        this.getCustomSettings();
        // this.getProfileIds();

        //  Promise.all([
        //     this.getCustomSettings(),
        //     this.getProfileIds()
        // ]).then(() => this.getProfileOptions());
    }

    get occurenceOptions() {
        return [
            { label: 'Daily', value: 'Daily' },
            { label: 'Weekly', value: 'Weekly' },
            { label: 'Monthly', value: 'Monthly' }
        ];
    }

    get accountAddressOptions() {
        return [
            { label: 'Billing', value: 'Billing' },
            { label: 'Shipping', value: 'Shipping' }
        ];
    }

    get contactAddressOptions() {
        return [
            { label: 'Mailing', value: 'Mailing' },
            { label: 'Other', value: 'Other' }
        ];
    }

    async getCustomSettings(){
        try{
            const customSettWrapp = await getCustomSettings({});
            console.log('@@@ getCustomSettings');
            console.log(customSettWrapp);
            this.companyHouseAPI = customSettWrapp.companyHouseAPI;
            this.companyHouseSetting = customSettWrapp.companyHouseSetting;

            console.log(this.companyHouseAPI.Authorization__c);
            this.isSpinner = false;
        }catch(error){
            console.error(error);
        }
    }

    // async getProfileIds(){
    //     try{
    //         const profileList = await getProfileIds({});
    //         console.log('@@@ getProfileIds');
    //         console.log(profileList);
    //         this.profileList = profileList;
    //     }catch(error){
    //         console.error(error);
    //     }
    // }

    // async getProfileOptions(){
    //     try{
    //         const profileOptions = await getProfileOptions({});
    //         console.log('@@@ profileOptions');
    //         console.log(profileOptions);

    //         this.profileOptions = this.getLabelsObject(profileOptions);
    //         this.isSpinner = false;
    //     }catch(error){
    //         console.error(error);
    //     }
    // }

    // getLabelsObject(picklistVal){
    //     const labels = [];
    //     labels.push({label:'', value:''});
    //     picklistVal.forEach(function(pickVal){
    //         labels.push({label:pickVal.label, value:pickVal.value});
    //     });
    //     return labels;
    // }

    onFormChange(event){
        if(event.target.name == 'authorizationKey'){
            this.companyHouseAPI.Authorization__c = event.target.value;
        }
    }

    onUpdateCheckbox(event){
        if(event.target.name == 'autoUpdateAccount'){
            this.companyHouseSetting.Auto_Update_Accounts__c = event.target.checked;
        }
        else if(event.target.name == 'autoUpdateContact'){
            this.companyHouseSetting.Auto_Update_Contacts__c = event.target.checked;
        }
        else if(event.target.name == 'importOfficer'){
            this.companyHouseSetting.Import_Resigned__c = event.target.checked;
        }
    }

    onUpdateRadioGroup(event){
        console.log(event.target.value);
        if(event.target.name == 'batchOccurrence'){
            this.companyHouseSetting.Batch_Occurrence__c = event.target.value;
        }
        else if(event.target.name == 'accountAddress'){
            this.companyHouseSetting.Account_Address__c = event.target.value;
        }
        else if(event.target.name == 'contactAddress'){
            this.companyHouseSetting.Contact_Address__c = event.target.value;
        }
    }

    async saveCompanyHouseAPI(){
        try{
            this.isSpinner = true;
            await saveCompanyHouseAPI({companyHouseAPI: this.companyHouseAPI});
            const event = new ShowToastEvent({
                title: 'Success Message',
                message: 'Successfully Saved API Setting.',
                variant: 'success',
                mode: 'dismissable'
            });
            dispatchEvent(event);
            this.isSpinner = false;
        }catch(error){
            console.error(error);
            this.isSpinner = false;
        }
    }

    async saveCompanyHouseSetting(){
        try{
            this.isSpinner = true;
            await saveCompanyHouseSetting({companyHouseSetting: this.companyHouseSetting});
            const event = new ShowToastEvent({
                title: 'Success Message',
                message: 'Successfully Saved Batch Setting.',
                variant: 'success',
                mode: 'dismissable'
            });
            dispatchEvent(event);
            this.isSpinner = false;
        }catch(error){
            console.error(error);
            this.isSpinner = false;
        }
    }

    async saveCompanyHouseSetting2(){
        try{
            this.isSpinner = true;
            await saveCompanyHouseSetting({companyHouseSetting: this.companyHouseSetting});
            const event = new ShowToastEvent({
                title: 'Success Message',
                message: 'Successfully Saved Address Mapping Setting.',
                variant: 'success',
                mode: 'dismissable'
            });
            dispatchEvent(event);
            this.isSpinner = false;
        }catch(error){
            console.error(error);
            this.isSpinner = false;
        }
    }

    // addNewProfile(){
    //     console.log('@@@ addNewProfile');
    //     let listSize = this.profileList.length;
    //     listSize = listSize + 1;
    //     let randomId = Math.random() * 16;
    //     let myNewElement = {profileId: randomId, profileName: null, isDisabled: false, isNew: true, ctr: listSize};
    //     this.profileList = [...this.profileList, myNewElement];
    //     console.log('@@@ profileList');
    //     console.log(profileList);
    // }

    // onProfileChange(event){
    //     console.log('@@@ onProfileChange');
    //     var foundelement = this.profileList.find(ele => ele.profileId == event.target.dataset.id);
    //     foundelement.profileId = event.detail.value;
    //     console.log(foundelement.profileId);
    // }

    // deleteProfile(event){
    //     console.log('@@@ deleteProfile');
    //     var profileToDelete = this.profileList.find(ele => ele.profileId == event.target.dataset.id);
    //     console.log(profileToDelete);

    //     if(profileToDelete.profileName != 'System Administrator'){
    //         if(isNaN(profileToDelete.profileId)){
    //             // deleteBuyingPlans({
    //             //     buyingPlanToDeleteId: this.buyingPlanToDelete.Id
    //             // })
    //             // .then(result => {
    //             //     const evt = new ShowToastEvent({
    //             //         title: 'Success',
    //             //         message: 'Successfully Deleted Buying Plan record.',
    //             //         variant: 'success',
    //             //     });
    //             //     this.dispatchEvent(evt);
    
    //             //     this.getExistingBuyingPlans();
    //             // }).catch( error => {
    //             //      this.isSpinner = false;
    //             //     console.log('@@@ error deleteBuyingPlans: '+ JSON.stringify(error));
    //             // });
    //         }
    //         else{
    //             this.isSpinner = false;
    //         }
    //         this.profileList.splice(this.profileList.findIndex(row => row.profileId === profileToDelete.profileId), 1);
    //     }
    // }

    // async saveProfileSetting(){
    //     try{
    //         this.isSpinner = true;
    //         await saveProfileSetting({companyHouseSetting: this.companyHouseSetting});
    //         const event = new ShowToastEvent({
    //             title: 'Success Message',
    //             message: 'Successfully Saved Address Mapping Setting.',
    //             variant: 'success',
    //             mode: 'dismissable'
    //         });
    //         dispatchEvent(event);
    //         this.isSpinner = false;
    //     }catch(error){
    //         console.error(error);
    //         this.isSpinner = false;
    //     }
    // }
}