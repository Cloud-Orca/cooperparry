import { LightningElement, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import smartSearchLogoURL from '@salesforce/resourceUrl/smartSearchLogo';
import searchNameToSmartSearch from '@salesforce/apex/SmartSearchCompCont.searchNameToSmartSearch';
import getWactchlistSummary from '@salesforce/apex/SmartSearchCompCont.getWactchlistSummary';

export default class SmartSearchComp extends LightningElement {
    isSpinner;
    smartSearchLogo = smartSearchLogoURL;

    _recordId;
    @api set recordId(value) {
        this._recordId = value;
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
    fullName = '';

    cancelButton(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleChange(event){
        this[event.target.name] = event.target.value;
        console.log(this[event.target.name]);
    }

    async searchButton(){
        try{
            if(!this.firstName || this.lastName){
                this.isErrorMessage = true;
            }
            else{
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
}