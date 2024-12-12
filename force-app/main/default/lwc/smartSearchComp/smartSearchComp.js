import { LightningElement, api, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import smartSearchLogoURL from '@salesforce/resourceUrl/smartSearchLogo';
import searchNameToSmartSearch from '@salesforce/apex/SmartSearchCompCont.searchNameToSmartSearch';
import getDocument from '@salesforce/apex/SmartSearchCompCont.getDocument';
// import getWactchlistSummary from '@salesforce/apex/SmartSearchCompCont.getWactchlistSummary';
import getLifeCycleRole from '@salesforce/apex/SmartSearchCompCont.getLifeCycleRole';
import getAllBeneficialOwners from '@salesforce/apex/SmartSearchCompCont.getAllBeneficialOwners';
import getPicklistValues from '@salesforce/apex/SmartSearchCompCont.getPicklistValues';

export default class SmartSearchComp extends LightningElement {
    isSpinner;
    smartSearchLogo = smartSearchLogoURL;

    _recordId;
    @api set recordId(value) {
        this._recordId = value;
        this.isSpinner = true;
        this.checkLifecyleRole();
        this.getTitleOptions();
        this.getAllBeneficialOwners();
    }
    get recordId() {
        return this._recordId;
    }

    firstName;
    middleName;
    lastName;

    isResultScreen = false;
    isPassed = false;
    isErrorMessage = false;
    isDisplayLifecyleError = false;
    fullName = '';

    selectedOwnerId;
    hasOwnerSelected = false;

    isInputScreen = false;
    benOwnerToSearch;
    titleOptions = [];

    @track beneficialOwnerList;

    async checkLifecyleRole(){
        const isLifeCycleRoleExist = await getLifeCycleRole({
            recordId: this._recordId
        });
        this.isDisplayLifecyleError = (!isLifeCycleRoleExist) ? true : false;
    }

    async getAllBeneficialOwners(){
        let beneficialOwnerList = await getAllBeneficialOwners({
            recordId: this._recordId
        });
        console.log(beneficialOwnerList);
        this.beneficialOwnerList = beneficialOwnerList;

        this.beneficialOwnerList.forEach(item => {

            item.NameToDisplay = item.Title__c || '';
            item.NameToDisplay += (item.First_Name__c) ? ' ' + item.First_Name__c: '';
            item.NameToDisplay += (item.Middle_Name__c) ? ' ' + item.Middle_Name__c: '';
            item.NameToDisplay += (item.Last_Name__c) ? ' ' + item.Last_Name__c: '';

            item.AddressToDisplay = item.Flat__c || '';
            item.AddressToDisplay += (item.Building_Name_Number__c) ? ' ' + item.Building_Name_Number__c: '';
            item.AddressToDisplay += (item.Address_Line_1__c) ? ' ' + item.Address_Line_1__c: '';
            item.AddressToDisplay += (item.Address_Line_2__c) ? ' ' + item.Address_Line_2__c: '';
            item.AddressToDisplay += (item.Town__c) ? ' ' + item.Town__c: '';
            item.AddressToDisplay += (item.County__c) ? ' ' + item.County__c: '';
            item.AddressToDisplay += (item.Postcode__c) ? ' ' + item.Postcode__c: '';

            item.isChecked = false;

            item.StatusToDisplay = (item.Smart_Search_Status__c) ? item.Smart_Search_Status__c : 'Not Started';
        })

        this.isSpinner = false;
    }

    async getTitleOptions(){
        try{
            const picklistVal = await getPicklistValues({sObjectAPI:'Beneficial_Owner__c', fieldAPI: 'Title__c'});
            this.titleOptions = this.getLabelsObject(picklistVal);
        }catch(error){
            console.error(error);
        }
    }

    getLabelsObject(picklistVal){
        const labels = [];
        labels.push({label:'', value:''});
        picklistVal.forEach(function(pickVal){
            labels.push({label:pickVal.label, value:pickVal.value});
        });
        return labels;
    }

    renderedCallback(){
        let STYLE = document.createElement("style");
        STYLE.innerText = `.uiModal--medium .modal-container{
            width: 70% !important;
            max-width: 70%;
            min-width: 480px;
            max-height: 100%;
            min-height: 480px;
        }`;
        this.template.querySelector('lightning-card').appendChild(STYLE);
    }

    cancelButton(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleChange(event){
        this[event.target.name] = event.target.value;
        console.log(this[event.target.name]);
    }

    async searchButton(){
        try{
            const inputFields = this.template.querySelectorAll('lightning-input, lightning-combobox');
            var allValid = this.checkFieldsValidity(inputFields);

            if(allValid){
                this.isErrorMessage = false;
                this.isSpinner = true;
                console.log('searchNameToSmartSearch');
                const resp = await searchNameToSmartSearch({
                    recordId: this._recordId,
                    benOwnerToSearch: this.benOwnerToSearch
                });
                
                console.log(resp);
                // if(resp.isPass){
                    await this.delay(3000);
    
                    console.log('getDocument');
                    await getDocument({
                        recordId: this._recordId,
                        benOwnerId: this.benOwnerToSearch.Id,
                        subjectId: resp.subjectId
                    });
                    console.log('done');

                    const event = new ShowToastEvent({
                        title: 'Success Message',
                        message: 'Successfully Downloaded the Document.',
                        variant: 'success',
                        mode: 'dismissable'
                    });
                    dispatchEvent(event);
                // }

                this.isResultScreen = true;
                this.isPassed = resp.isPass;
                this.fullName = this.benOwnerToSearch.First_Name__c;
                this.fullName += (this.benOwnerToSearch.Middle_Name__c) ? ' ' + this.benOwnerToSearch.Middle_Name__c : '';
                this.fullName += (this.benOwnerToSearch.Last_Name__c) ? ' ' + this.benOwnerToSearch.Last_Name__c : '';
                this.isSpinner = false;
            }
        }catch(error){
            this.isSpinner = false;
            console.error(error);
        }
    }

    delay(milliseconds) {
        return new Promise(resolve => setTimeout(resolve, milliseconds));
    }

    checkFieldsValidity(fields){
        const allValid = [...fields,].reduce((validSoFar, field) => {
            field.reportValidity();
            return validSoFar && field.checkValidity();
        }, true);
        return allValid;
    }

    searchButtonAgain(){
        this.isResultScreen = false;
        this.isInputScreen = false;
        this.isPassed = false;
        this.isErrorMessage = false;
        this.fullName = '';

        this.isSpinner = true;
        this.getAllBeneficialOwners();
    }


    handleSelectOwner(event){
        console.log('@@@ handleSelectOwner');
        let rowId = event.currentTarget.value;
        this.selectedOwnerId = rowId;
        this.hasOwnerSelected = true;
        console.log(rowId);
        let rowIndex = this.beneficialOwnerList.findIndex(benOwner => benOwner.Id == rowId);
        console.log(rowIndex);
        let row = this.beneficialOwnerList[rowIndex];
        this.benOwnerToSearch = row;
        console.log(row);

        this.beneficialOwnerList.forEach(item => item.isChecked = (rowId === item.Id));
    }

    nextButton(){
        this.isInputScreen = true;
    }

    handleChangeOwnwer(event){
        let fieldName = event.currentTarget.name;
        this.benOwnerToSearch[fieldName] = event.currentTarget.value;
        console.log(this.benOwnerToSearch[fieldName]);
    }

    get isDisabledNext(){
        return !this.hasOwnerSelected || this.isDisplayLifecyleError;
    }
}