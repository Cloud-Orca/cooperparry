import { LightningElement, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import smartSearchLogoURL from '@salesforce/resourceUrl/smartSearchLogo';
import searchNameToSmartSearch from '@salesforce/apex/SmartSearchCompCont.searchNameToSmartSearch';
import getWactchlistSummary from '@salesforce/apex/SmartSearchCompCont.getWactchlistSummary';
import getLifeCycleRole from '@salesforce/apex/SmartSearchCompCont.getLifeCycleRole';

export default class SmartSearchComp extends LightningElement {
    isSpinner;
    smartSearchLogo = smartSearchLogoURL;

    _recordId;
    @api set recordId(value) {
        this._recordId = value;
        this.isSpinner = true;
        this.checkLifecyleRole();
    }
    get recordId() {
        return this._recordId;
    }

    firstName;
    middleName;
    lastName;

    isResultScreen = false;
    isPEPRCAIdentified = false;
    isErrorMessage = false;
    isDisplayLifecyleError = false;
    fullName = '';

    async checkLifecyleRole(){
        const isLifeCycleRoleExist = await getLifeCycleRole({
            recordId: this._recordId
        });
        this.isDisplayLifecyleError = (!isLifeCycleRoleExist) ? true : false;
        this.isSpinner = false;
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

            const inputFields = this.template.querySelectorAll('lightning-input');
            var allValid = this.checkFieldsValidity(inputFields);

            if(allValid){
                this.isErrorMessage = false;
                this.isSpinner = true;
                console.log('searchNameToSmartSearch');
                const searchSubjectId = await searchNameToSmartSearch({
                    recordId: this._recordId,
                    firstName: this.firstName,
                    middleName: this.middleName,
                    lastName: this.lastName
                });
    
                console.log(searchSubjectId);
                if(searchSubjectId){
                    await this.delay(5000);
    
                    console.log('getWactchlistSummary');
                    let smartSearchResult = await getWactchlistSummary({
                        recordId: this._recordId,
                        searchSubjectId: searchSubjectId
                    });
                    console.log('done');
                    console.log(smartSearchResult);
    
                    this.fullName = this.firstName;
                    this.fullName += (this.middleName) ? ' ' + this.middleName : '';
                    this.fullName += (this.lastName) ? ' ' + this.lastName : '';
    
                    if(smartSearchResult.isPEP || smartSearchResult.isRCA){
                        this.isPEPRCAIdentified = true;
                    }
                    else{
                        this.isPEPRCAIdentified = false;
                    }
    
                    this.isResultScreen = true;
                }
    
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
        this.isPEPRCAIdentified = false;
        this.isErrorMessage = false;
        this.fullName = '';

        this.firstName = '';
        this.middleName = '';
        this.lastName = '';
    }
}