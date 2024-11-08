import { LightningElement, wire , track, api } from 'lwc';
//import { CurrentPageReference } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions'; 
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import searchCompany from '@salesforce/apex/CompaniesHouseController.getCompanyByName';
import getFileHistories from '@salesforce/apex/CompaniesHouseController.getFillingHistories';
import getCompanyPeronsSignificantControl from '@salesforce/apex/CompaniesHouseController.getCompanyPeronsSignificantControl';
import getCompanyOfficers from '@salesforce/apex/CompaniesHouseController.getCompanyOfficers';
import getRelatedContacts from '@salesforce/apex/CompaniesHouseController.getExactMatchContacts';
import searchOtherContactMatch from '@salesforce/apex/CompaniesHouseController.searchOfficer';
import mergeSelectedOfficers from '@salesforce/apex/CompaniesHouseController.mergeSelectedOfficers';
import getOfficerFieldNameAndAPI from '@salesforce/apex/CompaniesHouseController.getOfficerFieldNameAndAPI';
import getCompanyByNumber from '@salesforce/apex/CompaniesHouseController.getCompanyByNumber';
import updateAccountContactConflicts from '@salesforce/apex/CompaniesHouseController.updateAccountOfficerFields';
import getCustomSettings from '@salesforce/apex/CompaniesHouseController.getCustomSettings';

import createNewOfficer from '@salesforce/apex/CompaniesHouse_OfficerFieldMapping.createNewOfficers';
import ACCOUNT_NAME_FIELD from '@salesforce/schema/Account.Name';
import COMPANY_NUMBER_FIELD from '@salesforce/schema/Account.Companies_House_Id__c';
import IsActive from '@salesforce/schema/Pricebook2.IsActive';

const ACCOUNT_FIELDS = [ACCOUNT_NAME_FIELD, COMPANY_NUMBER_FIELD];

const fileColumns = [
    { label: 'Date', fieldName: 'fileDate'},
    { label: 'Type', fieldName: 'fileType'},
    { label: 'Description', fieldName: 'fileDescription' },
    {
        label: 'View/Download',
        fieldName: 'downloadURL',
        type: 'url',
        typeAttributes: {label: { fieldName: 'fileDownloadName' }, 
        target: '_blank'},
        sortable: true
    },
];

export default class CompanyHouseButton extends LightningElement {
    @api recordId;
    @track isLoading = false;

    contactName = '';
    contactOfficerKey = '';
    selectedCompanyName = '';

    @track selectedStep = 'Step1';
    @track isShowPrevious = false;
    @track stepSearchDetails = true;
    @track stepCompanyDetails = false;
    @track stepPeopleDetails = false;
    @track stepConflictDetails = false;
    @track stepReviewDetails = false;

    stepFilesSelection  = false;
    stepPSC             = false;

    //Step Search Company
    @track isCompanyFound = false;
    @track isCompanyOfficersFound = false;
    @track isCompanyNumberToggle = false;
    @track searchCompLabel = 'Account Name';
    @track searchCompPlaceholder = 'Type Account Name';
    @track searchCompanyValue = null;
    @track showErrorOnInput = false;
    @track showErrorOnSearch = false;
    @track isLettersOnly = true;
    @track errorCompMessage = '';
    accountName = '';
    accountCompanyNumber = '';
    
    //Step Company Details
    @track results = [];
    @track selectedCompanyNumber = null;
    @track showErrorOnCompany = false;
    compData = {};
    companySignificantPersons = [];

    //Step People Details
    @track placeholder = 'Search';
    @track showSearchAnother = false;
    @track showMessageResult = false;
    @track selectedValues = false;
    @track showSearchedValues = false;
    @track closeMatchFound = false;
    @track searchKey = '';
    @track recordsList = [];
    @track offImportState = [];
    @track allSelectedContactList = [];
    @track mismatchFields= [];
    //@track searchedContacts = [];
    @track matchContacts = [];
    @track objRecordId = null;

    //Step Conflict
    @track matchHasNoConflict = false;
    activeSectionMessage = '';
    companyJson = [];
    jsonString = [];
    fields = [];
    fieldKeySet = [];
    allContactFields = [];
    allContactsForReview = [];
    contactsToUpdate = [];
    createdContacts = [];
    fieldLabel = '';
    recordselected = false;
    error;
    disableFinishBtn = true;

    fileData = [];
    fileColumns = fileColumns;
    fileDataSelected = [];

    pscData = [];
    pscDataActive = [];

    //STEP 1 : GET COMPANY NAME
    @wire(getRecord, { recordId: '$recordId', fields: ACCOUNT_FIELDS })
    wiredAccount({ error, data }){
        if(data){ 
            this.accountName = getFieldValue(data, ACCOUNT_NAME_FIELD);
            this.accountCompanyNumber = getFieldValue(data, COMPANY_NUMBER_FIELD);
            this.searchCompanyValue = this.accountName;
        } else if (error) {
            this.error = error;
            console.log('Error: Check Account Name and Account Company Number.');
        }
    }

    //GET COMPANIES HOUSE SETTINGS
    @wire(getCustomSettings)
    companiesHouseSettings;

    //ONCLICK NEXT BUTTON
    handleNext() {
        var getselectedStep = this.selectedStep;
        console.log('Get Selected Step:: ' + getselectedStep);
        if(getselectedStep === 'Step1'){ //SEARCH
            console.log('this.searchCompanyValue::' + this.searchCompanyValue);
            if(this.searchCompanyValue != null && this.searchCompanyValue !== ''){
                this.getCompanyHouseByNameOrByNum(this.searchCompanyValue);
                this.selectedStep = 'Step2';
                this.isShowPrevious = true;
                this.isLoading = true;
                
                // window.setTimeout(() => { 
                //     if(this.isCompanyFound){
                //         this.isLoading = false;
                //         this.stepSearchDetails = false;
                //         this.stepCompanyDetails = true;
                //     } 
                //     // else {
                //     //     this.selectedStep = 'Step1';
                //     //     this.stepSearchDetails = true;
                //     //     this.stepCompanyDetails = false;
                //     //     this.showErrorOnInput = true;
                //     //     this.showErrorOnSearch = true;
                //     //     this.errorCompMessage = 'Search not found. Please try again.';
                //     // }
                // }, 2000);

                if(this.isCompanyFound){
                    this.isLoading = false;
                    this.stepSearchDetails = false;
                    this.stepCompanyDetails = true;
                } 
                this.displayStepBody(this.selectedStep);
            } else{
                this.errorCompMessage = 'Complete this field.';
                this.showErrorOnInput = true;
                this.showErrorOnSearch = true;
            }
        } else if (getselectedStep === 'Step2'){ //COMPANY
            console.log('this.selectedCompanyNumber::' + this.selectedCompanyNumber);
            if(this.selectedCompanyNumber != null && this.selectedCompanyNumber !== ''){
                this.selectedStep = 'Step3';
                this.isShowPrevious = true;
                this.isLoading = true;
                this.stepCompanyDetails = false;

                this.getFile(this.selectedCompanyNumber);
                this.isLoading = false;
                this.stepFilesSelection = true;
            } else {
                this.showToast('No Record Selected!', 'Please select a company.', 'error', 'dismissable');
            }
        } else if(getselectedStep === 'Step3'){
            if(this.selectedCompanyNumber != null && this.selectedCompanyNumber !== ''){
                this.getCompanyOfficers(this.selectedCompanyNumber);
                this.selectedStep = 'Step4';
                this.isShowPrevious = true;
                this.stepFilesSelection = false;
                if(this.isCompanyOfficersFound){
                    this.stepPeopleDetails = true;
                }
                this.isLoading = false;
            }
            this.displayStepBody(this.selectedStep);
        } else if (getselectedStep === 'Step4'){ //PEOPLE
            this.isShowPrevious = true;
            this.isLoading = true;
            this.showSearchedValues = false;
            let officersToCreate = [];
            this.offImportState.forEach(state => {
                if(state.importAction.values.create == true){
                    officersToCreate.push(state.officerKey);
                }
            });

            if(Array.isArray(officersToCreate)){
                this.findConflictsOnContacts(this.recordId, JSON.stringify(officersToCreate), this.jsonString);
                this.selectedStep = 'Step5';
                this.isShowPrevious = true;
                this.isLoading = true;
                this.stepPeopleDetails = false;
                this.getPSC();
                this.stepPSC = true;
                this.displayStepBody(this.selectedStep);
            } else {
                this.showToast('No Record Selected!', 'Please complete all selection.', 'error', 'dismissable');
                this.showErrorOnInput = true;
                this.showErrorOnSearch = true;
            }
        } else if(getselectedStep === 'Step5'){
            this.selectedStep = 'Step6';
            this.isShowPrevious = true;
            this.isLoading = true;
            this.stepPSC = false;
            if(this.mismatchFields.length === 0 || this.mismatchFields == []){
                console.log('No conflicts found!');
                this.isLoading = false;
                //this.showToast('Success!', 'No conflicts found. Please proceed to the next step', 'success', 'dismissable');
                this.stepConflictDetails = true;
            } else {
                this.isLoading = false;
                this.showToast('Success!', 'Mismatch Information Found.', 'success', 'dismissable');
                this.stepConflictDetails = true;
            }
        } else if (getselectedStep === 'Step6'){ //CONFLICT
            if(this.mismatchFields != [] && !this.matchHasNoConflict && (this.contactsToUpdate.length == 0 || this.contactsToUpdate.length == [])){
                this.showToast('No Values Selected!', 'Please select values for the fields with conflict.', 'error', 'dismissable');
            } else {
                console.log('@@@ test jo');
                console.log('this.matchHasNoConflict: ' + this.matchHasNoConflict);
                console.log('this.mismatchFields: ' + this.mismatchFields);
                console.log('this.contactsToUpdate.length: ' + this.contactsToUpdate.length);

                this.selectedStep = 'Step7';
                this.isShowPrevious = true;
                this.isLoading = true;
                this.stepConflictDetails = false;

                // if(this.matchHasNoConflict == true){
                    Promise.all([
                        this.getFieldApiNamesAndValues()
                    ]).then(() => this.turnOffLoad());
                // }

                getCompanyByNumber({ 
                    companyNum: this.selectedCompanyNumber
                })
                .then(result => {
                    let parsedResult = JSON.parse(result);
                    this.companyJson = parsedResult.body;
                    console.log('get company by number parsed response');
                    console.log(parsedResult);
                    
                    if(parsedResult.status == 'OK' && parsedResult.statusCode == 200){
                        this.compData = JSON.parse(parsedResult.body);
                        this.stepReviewDetails = true;
                        this.displayStepBody(this.selectedStep);
                        if(this.matchHasNoConflict == false){
                            // this.isLoading = false;
                            // this.disableFinishBtn = false;
                        }
                    }  
                })
                .catch(error => {
                    console.log('An error has occurred');
                    console.log(JSON.stringify(error));
                });
            }
        } 
    }

    async turnOffLoad(){
        console.log('@@@@@@ turnOffLoad');
        this.isLoading = false;
        this.disableFinishBtn = false;
    }

    //ONCLICK PREVIOUS BUTTON
    handlePrev() {
        var getselectedStep = this.selectedStep;
        if(getselectedStep === 'Step2'){
            this.selectedStep = 'Step1';
            this.stepCompanyDetails = false;
            this.isLoading = true;
            window.setTimeout(() => { 
                this.isLoading = false;
                this.stepSearchDetails = true;
            }, 2000);
            this.isShowPrevious = false;
            this.displayStepBody(this.selectedStep);
        }else if(getselectedStep === 'Step3'){
            this.selectedStep = 'Step2';
            this.stepFilesSelection = false;
            this.isLoading = true;
            window.setTimeout(() => { 
                this.isLoading = false;
                this.stepCompanyDetails = true;
            }, 2000);

            this.displayStepBody(this.selectedStep);
        } else if(getselectedStep === 'Step4'){ 
            this.selectedStep = 'Step3';
            this.stepPeopleDetails = false;
            this.isLoading = true;
            window.setTimeout(() => { 
                this.isLoading = false;
                this.stepFilesSelection = true;
            }, 2000);

            this.displayStepBody(this.selectedStep);
        } else if(getselectedStep === 'Step5'){
            this.selectedStep = 'Step4';
            this.stepPSC = false;
            this.isLoading = true;
            window.setTimeout(() => { 
                this.isLoading = false;
                this.stepPeopleDetails = true;
            }, 2000);

            this.displayStepBody(this.selectedStep);
        } else if(getselectedStep === 'Step6'){
            this.selectedStep = 'Step5';
            this.stepConflictDetails = false;
            this.isLoading = true;
            window.setTimeout(() => { 
                this.isLoading = false;
                this.stepPSC = true;
            }, 2000);

            this.displayStepBody(this.selectedStep);
        } else if(getselectedStep === 'Step7'){
            this.selectedStep = 'Step6';
            this.stepReviewDetails = false;
            this.isLoading = true;
            window.setTimeout(() => { 
                this.isLoading = false;
                this.stepConflictDetails = true;
            }, 2000);

            this.displayStepBody(this.selectedStep);
        }
    }

    //OVERALL DISPLAY BODY
    displayStepBody(stepvalue){
        if(stepvalue === 'Step1'){
           this.stepSearchDetails = true;
           this.stepCompanyDetails = false;
           this.stepFilesSelection = false;
           this.stepPeopleDetails = false;
           this.stepPSC = false;
           this.stepConflictDetails = false;
           this.stepReviewDetails = false;
        } else if(stepvalue === 'Step2'){
            this.stepSearchDetails = false;
            this.stepCompanyDetails = true;
            this.stepFilesSelection = false;
            this.stepPeopleDetails = false;
            this.stepPSC = false;
            this.stepConflictDetails = false;
            this.stepReviewDetails = false;
        } else if(stepvalue === 'Step3'){
            this.stepSearchDetails = false;
            this.stepCompanyDetails = false;
            this.stepFilesSelection = true;
            this.stepPeopleDetails = false;
            this.stepPSC = false;
            this.stepConflictDetails = false;
            this.stepReviewDetails = false;
        } else if(stepvalue === 'Step4'){
            this.stepSearchDetails = false;
            this.stepCompanyDetails = false;
            this.stepFilesSelection = false;
            this.stepPeopleDetails = true;
            this.stepPSC = false;
            this.stepConflictDetails = false;
            this.stepReviewDetails = false;
        } else if(stepvalue === 'Step5'){
            this.stepSearchDetails = false;
            this.stepCompanyDetails = false;
            this.stepFilesSelection = false;
            this.stepPeopleDetails = false;
            this.stepPSC = true;
            this.stepConflictDetails = false;
            this.stepReviewDetails = false;
        } else if(stepvalue === 'Step6'){
            this.stepSearchDetails = false;
            this.stepCompanyDetails = false;
            this.stepFilesSelection = false;
            this.stepPeopleDetails = false;
            this.stepPSC = false;
            this.stepConflictDetails = true;
            this.stepReviewDetails = false;
        } else if(stepvalue === 'Step7'){
            this.stepSearchDetails = false;
            this.stepCompanyDetails = false;
            this.stepFilesSelection = false;
            this.stepPeopleDetails = false;
            this.stepPSC = false;
            this.stepConflictDetails = false;
            this.stepReviewDetails = true;
        }
    }

    //ONCLICK FINISH BUTTON
    handleFinish() {
        this.isLoading = true;
        this.stepReviewDetails = true;
        console.log('this.recordId::' + this.recordId);
        console.log('this.selectedCompanyNumber::' + this.selectedCompanyNumber);
        console.log('this.companyJson::' + JSON.stringify(this.companyJson));
        console.log('this.contactsToUpdate::' + JSON.stringify(this.contactsToUpdate));
        console.log('this.jsonString::' + JSON.stringify(this.jsonString));

        let activepcsData = this.pscData.filter( item => !item.ceased );
        console.log('activepcsData' + JSON.stringify(activepcsData));
        updateAccountContactConflicts({
            accountId : this.recordId,
            companyKey : this.selectedCompanyNumber,
            jsonString : this.companyJson,
            officersForUpdates : this.contactsToUpdate,
            jsonOfficers : this.jsonString,
            params : this.fileDataSelected,
            pcsData : activepcsData
        }).then(result => {
            this.isLoading = false;
            console.log('SUCCESS UPDATE:' + result);
            this.showToast('Success!', 'Account and Officer successfully updated', 'success', 'dismissable');
            //window.location.reload();
            this.dispatchEvent(new CloseActionScreenEvent());
        }) .catch(error => {
            this.showToast('Error!', 'An error has occured. Error: '+ error.body.message, 'error', 'dismissable');
            console.log('An error has occurred');
            console.log(error);
        })
    }

    //STEP 1 : SHOW ERROR ON COMPANY SEARCH
    get showError(){
        return this.showErrorOnInput ? 'slds-form-element slds-has-error' : 'slds-form-element';
    }

    //STEP 1 : GET CORRECT PATTERN
    get inputPattern() {
        return this.isLettersOnly ? /^[a-zA-Z][a-zA-Z0-9 ]*$/gm : /^[0-9]+$/;
    }

    //STEP 1 : GET ERROR MESSAGE FOR BAD INPUT
    get inputErrorMessage() {
        return this.isLettersOnly ? 'Please enter a valid company name' : 'Please enter a valid company number';
    }

    handleKeyDown(event) {
        // const inputValue = event.target.value;
        // const keyPressed = event.key;

        console.log('this.inputPattern::' + this.inputPattern);
        console.log('evt target val: '+event.target.value);

        if(!event.target.value.match(this.inputPattern) && event.key !== ' '){
            this.errorCompMessage = this.inputErrorMessage;
            this.showErrorOnInput = true;
            this.showErrorOnSearch = true;
        } else {
            this.showErrorOnInput = false;
            this.showErrorOnSearch = false;
        }

        let futureSearchVal = (this.searchCompanyValue ? this.searchCompanyValue+''+event.key : ''+event.key);
        console.log('futureSearchVal: '+this.searchCompanyValue);
        console.log('inputPattern match?: '+futureSearchVal.match(this.inputPattern));
        if(event.key.length === 1 && !futureSearchVal.match(this.inputPattern) && event.key !== ' ') {
            event.preventDefault();
        }
    }

    //STEP 1 : TOGGLE SWITCH
    changeToggle(event){
        this.isLettersOnly = !this.isLettersOnly;
        this.isCompanyNumberToggle = !this.isCompanyNumberToggle;
        if(this.isCompanyNumberToggle){
            this.checked = true;
            // if(!this.accountCompanyNumber){
            //     this.dispatchEvent(new CloseActionScreenEvent());
            //     this.showToast('Missing Information!', 'Please populate Account Company Number.', 'error', 'dismissable');
            // } else {
            //     this.searchCompLabel = 'Company Number';
            //     this.searchCompPlaceholder = 'Type Company Number';
            //     this.searchCompanyValue = this.accountCompanyNumber;
            // }
            this.searchCompLabel = 'Company Number';
            this.searchCompPlaceholder = 'Type Company Number';
            this.searchCompanyValue = this.accountCompanyNumber;
            this.isLettersOnly = false;
        }else{
            this.checked = false;
            this.searchCompLabel = 'Account Name';
            this.searchCompPlaceholder = 'Type Account Name';
            this.searchCompanyValue = this.accountName;
            this.isLettersOnly = true;
        }
    }

    //STEP 1 : HANDLES COMPANY NAME ON CHANGE TO SEARCH
    handleCompanySearchChange(event){
        const searchValue = event.detail.value;
        this.searchCompanyValue = searchValue;
    }

    //STEP 1 : HANDLES COMPANY NUMBER ON CHANGE TO SEARCH
    // handleCompanyNumSearchChange(event){
    //     const searchValue = event.detail.value;
    //     this.searchCompanyValue = searchValue;
    // }

    //STEP 1 : GET COMPANY LIST BY COMPANY NAME OR COMPANY NUMBER FROM COMPANIES HOUSE API
    async getCompanyHouseByNameOrByNum(compValue){
        this.isLoading = true;
        searchCompany({
            companyName: compValue
        }).then(result => {
            this.isCompanyFound = true;
            let parsedRes = JSON.parse(result);
            console.log('@@@ ok');
            if(parsedRes.status === 'OK' && parsedRes.statusCode === 200 && parsedRes.body){
                let parsedBody = JSON.parse(parsedRes.body);
                this.isLoading = false;
                if(parsedBody.items && parsedBody.items.length > 0){
                    let newResults = parsedBody.items.map(item => {
                        console.log('@@@ item.title: ' + item.title);
                        console.log('@@@ item.address: ' + item.address);
                        if(item.address != null){
                            item.address.premises = item.address.premises  + ' ' + item.address.address_line_1;
                        }
                        // item.address.premises = item.address.premises  + ' ' + item.address.address_line_1;
                        if(compValue.selectedCompNum === item.company_number){
                            item.isChecked = true;
                        }
                        if(this.selectedCompanyNumber == null || this.selectedCompanyNumber == ''){
                            this.selectedCompanyNumber = item.company_number;
                        }
                        return item;
                    });
                    this.results = JSON.parse(JSON.stringify(newResults));
                    console.log('Company Search Results:: ' + JSON.stringify(this.results));
                    this.showToast('Success!', 'Company Record Found!', 'success', 'dismissable');
                } else {
                    console.log('Has No Searched Company');
                    this.results = [];
                    this.selectedStep = 'Step1';
                    this.stepSearchDetails = true;
                    this.stepCompanyDetails = false;
                    this.showErrorOnInput = true;
                    this.showErrorOnSearch = true;
                    this.errorCompMessage = 'Search not found. Please try again.'
                }
            }
        }).catch(error => {
            this.showToast('Error!', 'Error: '+ error.body.message, 'error', 'dismissable');
            console.log('Get Company Error: '+ JSON.stringify(error));
        });
    }

    //STEP 2 : HANDLE ON COMPANY SELECTION
    handleClickCompany(event){
        this.selectedCompanyNumber = event.currentTarget.value;
        this.results.forEach(item => {
            if(item.company_number === this.selectedCompanyNumber){
                this.selectedCompanyName = item.title;
            }
        })
        console.log('Selected Company:: ' + event.currentTarget.value);
    }

    handleRowSelection(event){
        var selectedRows        = event.detail.selectedRows;
        
        console.log('selectedRows' + JSON.stringify(selectedRows));
        this.fileDataSelected   = selectedRows;
    }
 
    async getFile(selectedCompanyNumber){
        getFileHistories({companyNum: selectedCompanyNumber})
        .then(result => {
            console.log('result', result); 
            let parsedResponse = JSON.parse(result);
            if(parsedResponse.status === 'OK' && parsedResponse.statusCode === 200 && parsedResponse.body){
                let parsedBody = JSON.parse(parsedResponse.body);
                let data = [];
                parsedBody.items.forEach(item => {
                    data.push({
                        fileDate : item.date,
                        fileType : item.type,
                        fileDescription : item.description.replaceAll('-', ' '),
                        fileDownloadName : 'View PDF',
                        downloadURL : 'https://find-and-update.company-information.service.gov.uk/company/'+selectedCompanyNumber+'/filing-history/'+item.transaction_id+'/document?format=pdf&download=0'
                    });
                });
                this.fileData = data;
                console.log('this.fileData', JSON.stringify(this.fileData));
            }
            
        })
        .catch(error => {
            console.log('Get File Histories Error'+ JSON.stringify(error));
            this.showToast('Error!', 'Error: '+ error.body.message, 'error', 'dismissable');
        });
    }

    //STEP 3 : GET COMPANY OFFICERS FROM COMPANIES HOUSE API
    async getCompanyOfficers(selectedCompanyNumber){
        this.isLoading = true;
        getCompanyOfficers({ 
            companyNum : selectedCompanyNumber
        }).then(result => {         
            let parsedResult = JSON.parse(result);
            if(parsedResult.status === 'OK' && parsedResult.statusCode === 200){
                let parsedBody = JSON.parse(parsedResult.body);
                this.jsonString = parsedResult.body;

                if(parsedBody && Array.isArray(parsedBody.items) && parsedBody.items.length > 0){
                    let offImportState = [];
                    let officerIds = [];
                    this.isCompanyOfficersFound = true;
                    console.log('parsedBody.items:: ' + JSON.stringify(parsedBody.items));
                    
                    parsedBody.items.forEach(item => {
                        let key = this.getOfficerNumFromLink(item.links.self);
                        let officerDateOfBirth = this.formatOfficerDOB(item.date_of_birth);

                        offImportState.push({
                            officerKey : key,
                            officerData : item,
                            officerDateOfBirth : officerDateOfBirth,
                            importAction : {
                                ids : {
                                    donotId : 'donot-'+key,
                                    searchanotherId : 'search-'+key,
                                    createId : 'create-'+key,
                                    matchContactId : 'match-'+key
                                },
                                values : {
                                    doNotImport : false,
                                    searchAnother : false,
                                    create : false,
                                    matchContact : false
                                }
                            },
                            selectedMatch : null,
                            closeMatches : [],
                            exactMatch : null
                        });
                        officerIds.push(key);
                        console.log('getRelatedContacts (offImportState original) :: ' + JSON.stringify(offImportState));
                    });

                    //Get Exact Matches in Contact
                    getRelatedContacts({ 
                        officerNums : officerIds,
                        recordId : this.recordId
                    }).then(item => {
                        console.log('getRelatedContacts (item) :: ' + JSON.stringify(item));
                        this.isLoading = false;
                        let officerNames = [];
                        offImportState.forEach(state => {
                            let officerKey = state.officerKey;
                            state.exactMatch = item[officerKey] ? item[officerKey] : null;
                            
                            if (this.companiesHouseSettings.data.Import_Resigned__c != true && state.officerData.resigned_on) {
                                state.exactMatch = officerKey;
                            }

                            if(state.exactMatch == null){
                                officerNames.push(state.officerData.name);
                            }
                                                        
                        });

                        this.offImportState = offImportState;
                        this.searchContactName(officerNames);
                        this.showToast('Success!', 'Company Officers Found!', 'success', 'dismissable');
                        console.log('getRelatedContacts (offImportState after) :: ' + JSON.stringify(offImportState));
                    })
                    .catch(error => {
                        this.showToast('Error!', 'An error has occured. Error: '+ error.body.message, 'error', 'dismissable');
                        console.log('Get Related Contact Error :: ' + JSON.stringify(error));
                    });
                }
            }
        })
        .catch(error => {
            this.showToast('Error!', 'An error has occured. Error: '+ error.body.message, 'error', 'dismissable');
            console.log('Get Company Officers Error :: ' + JSON.stringify(error));
        });
    }

    //STEP 3 : GET OFFICER KEY
    getOfficerNumFromLink(link){
        let splitLink = link.split('/');
        let finalOfficerKey = splitLink[splitLink.length - 1];
        return finalOfficerKey;
    }

    //STEP 3 : GET OFFICER BIRTH DAY 
    formatOfficerDOB(dateOfBirth){
        if(dateOfBirth != null){
            let { year, month } = dateOfBirth;
            let newDOBFormat = new Date(Date.UTC(2000, month - 1, 1)).toLocaleString('en-US', { month: 'short' });
            return `${newDOBFormat} ${year}`;
        }
    }

    //STEP 3 : GET SELECTED OPTIONS [DoNotImport...SearchMatch...CreateNewOfficer..CloseMatches]
    handleImportOptClicked(event){   
        let officerKey = event.target.name;
        let matchedId = event.target.id;
        //let recordId = event.target.id;
        let selectedValue = event.target.value; 
        // let selectedKey = [...this.selectedOfficerKey];
        this.showSearchAnother = false;
        console.log('officerKey: '+ officerKey);
        console.log('selectedValue: ' + selectedValue);
    
        matchedId = matchedId.replace('search-', '').replace('create-', '').replace('donot-', '');
        matchedId = matchedId.replace(/-\d+$/, '');

        console.log('matchedId:: ' + matchedId);

        let stateIndex = this.offImportState.findIndex(state => state.officerKey === officerKey);
        let importState = this.offImportState[stateIndex];

        if (selectedValue == 'doNotImport') {
            // selectedKey = selectedKey.filter(record => record !== recordId);
            this.showSearchAnother = false;
            importState.importAction.values.doNotImport = true;
            importState.importAction.values.create = false;
            importState.importAction.values.searchAnother = false;
            importState.importAction.values.matchContact = false;
        }
        
        if (selectedValue == 'createNew') {
            this.showSearchAnother = false;
            importState.importAction.values.doNotImport = false;
            importState.importAction.values.create = true;
            importState.importAction.values.searchAnother = false;
            importState.importAction.values.matchContact = false;
        } 
        
        if (selectedValue == 'searchAnother') {
            // selectedKey = selectedKey.filter(record => record !== recordId);
            importState.importAction.values.doNotImport = false;
            importState.importAction.values.create = false;
            importState.importAction.values.searchAnother = true;
            importState.importAction.values.matchContact = false;
        }

        if (selectedValue == 'matchContact') {
            // selectedKey = selectedKey.filter(record => record !== recordId);
            importState.importAction.values.doNotImport = false;
            importState.importAction.values.create = false;
            importState.importAction.values.searchAnother = false;
            importState.importAction.values.matchContact = true;
        } 

        //this.offImportState[stateIndex] = importState;

        
        if (importState.importAction.values.matchContact == true) {
            const matchedCloseMatch = importState.closeMatches.find(closeMatch => closeMatch.id === matchedId);
            if (matchedCloseMatch) {
                importState.selectedMatch = matchedId;
            } else {  
                console.log('No match found for matchedId');
            }
        }

        this.offImportState[stateIndex] = importState;
        console.log('handleImportOptClicked this.offImportState:: ' + JSON.stringify(this.offImportState));  
    }

    //STEP 3 : HANDLE SELECTION OF SEARCHED ANOTHER CONTACT MATCH
    handleRecordSelection(event) { 
        this.showSearchedValues = false;
        this.showMessageResult = false;
        const selectedOfficerKey = event.currentTarget.dataset.officerKey;
        let selectedContId = event.currentTarget.value;
        console.log('selectedContId: '+selectedContId);

        let offImportStateToUpdate = [...this.offImportState];
        
        offImportStateToUpdate = offImportStateToUpdate.map(state => {
            if (state.officerKey === selectedOfficerKey) {
                return {
                    ...state,
                    selectedMatch: selectedContId,
                };
            }
            return state;
        });
        
        this.offImportState = offImportStateToUpdate;
    }

    //STEP 3 : GET TOP 5 MATCHING CONTACTS FROM OFFICER NAME KEY
    searchContactName(officerNames){
        console.log('searchContactName officerList:: ' + JSON.stringify(officerNames));
        searchOtherContactMatch({ 
            searchKey: officerNames,
        }).then( result => {
            //this.searchedContacts = result;
            console.log('searchContactName result:: ' + JSON.stringify(result));
            console.log('searchContactName result.length:: ' + result.length);
            if (result && result.length > 0) {
                this.offImportState.forEach((state) => {
                    if (state.exactMatch === null) {

                        let officerNameParts = state.officerData.name.split(/[ ,]+/);
                        let topMatchingContacts = [];
                        result.forEach(contact => {
                            if (officerNameParts.some(part => contact.Name.toLowerCase().includes(part.toLowerCase()))) {
                                topMatchingContacts.push({
                                    officerKey: state.officerKey,
                                    id : contact.Id,
                                    name: contact.Name,
                                    fieldValues: contact,
                                    className: 'ModelTooltip_' + state.officerKey + contact.Id
                                });
                                
                                if (topMatchingContacts.length > 0 && topMatchingContacts.length <= 5) {
                                    state.closeMatches = topMatchingContacts;
                                } else {
                                    state.closeMatches = topMatchingContacts.slice(0, 5);
                                }
                            } 
                        });
                    }
                    
                });
                console.log('searchContactName this.offImportState:: ' + JSON.stringify(this.offImportState));  
            }

            this.getPersonWithSignificantControl();
        }).catch( error => {
            console.log('searchContactName error:: ' + JSON.stringify(error));
            this.showToast('Error!', 'An error has occured. Error: '+ error.body.message, 'error', 'dismissable');
        });
    }

    async getPersonWithSignificantControl(){
        this.isLoading = true;
        let result = await getCompanyPeronsSignificantControl({
            companyNum: this.selectedCompanyNumber
        });
        if(result){
            let parsedResult = JSON.parse(result);
            if(parsedResult.status == 'OK' && parsedResult.statusCode == 200){
                let parsedBody = JSON.parse(parsedResult.body);
                if(Array.isArray(parsedBody.items)){
                    this.companySignificantPersons = parsedBody.items;
                }
            }
        }
        this.isLoading = false;
    }

    async getPSC(){
        this.isLoading = true;
        let result = await getCompanyPeronsSignificantControl({
            companyNum: this.selectedCompanyNumber
        });
        if(result){
            let parsedResult = JSON.parse(result);
            if(parsedResult.status == 'OK' && parsedResult.statusCode == 200){
                let parsedBody = JSON.parse(parsedResult.body);
                if(Array.isArray(parsedBody.items)){

                    let parsedData  = [];
                    parsedBody.items.forEach(item => {
                        if( item.kind  == 'individual-person-with-significant-control' ){
                            parsedData.push({
                                Id          : item.etag,
                                fullName    : item.name,
                                birthdate   : this.formatOfficerDOB(item.date_of_birth),
                                status      : item.ceased ? 'Not Active' : 'Active',
                                isActive    : !item.ceased,
                                importData  : {
                                    donotimport : true,
                                    isMatch     : false,
                                    isNew       : false
                                },
                                isSelectedRecord : '',
                                matchRecords : [],
                                item        : item 
                            });
                        }
                    });

                    this.pscData = parsedData; 
                }
            }
        }
        this.isLoading = false;
    }

    //STEP 3 : HANDLE CREATE NEW CONTACT RECORD
    findConflictsOnContacts(recordId, officerKey, jsonString){
        console.log('@@@ companySignificantPersons');
        console.log(JSON.stringify(this.companySignificantPersons));
        this.isLoading = true;
        createNewOfficer({ 
            accountId   : recordId,
            officerKey  : officerKey,
            jsonString  : jsonString,
            jsonString2 : JSON.stringify(this.companySignificantPersons),
            proceedCreate   : true
        }).then(result => {
            this.createdContacts = result;
            console.log('Created New Contact result:: ' + JSON.stringify(this.createdContacts));
            console.log('Created New Contact Id:: ' + JSON.stringify(this.createdContacts.Id));
            console.log('Created New Contact Name:: ' + JSON.stringify(this.createdContacts.Name));

            //merge contacts searched and created contacts
            // console.log('searchedContactIds in createContact' +this.searchedContactIds);
            if(this.createdContacts){
                this.isLoading = true;
            }

            let searchedContacts = [];
            let matchedContacts = [];

            this.offImportState.forEach(state => {
                if(state.importAction.values.searchAnother == true && state.selectedMatch){
                    searchedContacts.push(state.selectedMatch);
                }

                if(state.importAction.values.matchContact == true && state.selectedMatch){
                    matchedContacts.push(state.selectedMatch);
                }
            });

            let existingOfficers = [];

            this.offImportState.forEach(state => {
                if(state.exactMatch != null){
                    existingOfficers.push(state.exactMatch.Id);
                }
            });

            console.log('existingOfficers:: ' + existingOfficers);

            mergeSelectedOfficers({
                existingOfficerIds : existingOfficers,
                searchedContactIds : searchedContacts,
                createdContactList : this.createdContacts,
                matchContactIds: matchedContacts
            }).then(data => {
                if(data && data.length > 0){
                    
                    this.allSelectedContactList = data;
                    console.log('this.allSelectedContactList in mergeSelectedOfficers:: ' + JSON.stringify(this.allSelectedContactList));
                    console.log('this.offImportState in mergeSelectedOfficers:: '  + JSON.stringify(this.offImportState));

                    // Iterate through this.offImportState and check for matching fields
                    this.mismatchFields = [];

                    this.offImportState.forEach(state => {
                        let contactListObj;
                        if(state.exactMatch != null){ //&& state.officerData.resigned_on == null //Add all existing Officers in SF
                            contactListObj = this.allSelectedContactList.find(cont => cont.Id == state.exactMatch.Id);
                        } else if(state.importAction.values.searchAnother){
                            contactListObj = this.allSelectedContactList.find(cont => cont.Id == state.selectedMatch);
                        } else if(state.importAction.values.create){
                            contactListObj = this.allSelectedContactList.find(cont => cont.Officer_Key__c == state.officerKey);
                        } else if(state.importAction.values.matchContact){
                            contactListObj = this.allSelectedContactList.find(cont => cont.Id == state.selectedMatch);
                        }

                        console.log('contactListObj::' + JSON.stringify(contactListObj));

                        if(contactListObj){
                            let personData;

                            if(Array.isArray(this.companySignificantPersons)){
                                personData = this.companySignificantPersons.find(person => {
                                    let personName = person.name_elements?.surname+', '+person.name_elements?.forename+(person.name_elements?.middle_name ? ' '+person.name_elements?.middle_name : '');
                                    if(personName.toLowerCase() == state.officerData.name.toLowerCase()){
                                        return true;
                                    }
                                    return false;
                                });
                            }

                            let mismatchRow = {
                                sfId : contactListObj.Id,
                                sfName : contactListObj.Name,
                                sfOfficerKey : state.officerKey,
                                sfSelectedId : 'selectedAllSFValues-' + contactListObj.Id,
                                chSelectedId : 'selectedAllCHValues-' + contactListObj.Id,
                                // sfselectAll : true,
                                // chSelectAll : false,
                                mismatchedFields: [],
                            };

                            //MISMATCH NAME
                            let compHouseOfficerName = state.officerData.name;
                            if(!compHouseOfficerName && personData){
                                compHouseOfficerName = personData.name_elements.surname+', '+personData.name_elements.forename+(personData.name_elements.middle_name ? ' '+personData.name_elements.middle_name : '');
                            }

                            const salutations = ['Mr', 'Ms', 'Mrs', 'Dr', 'Prof', 'Mx'];
                            salutations.forEach(salutation => {
                                compHouseOfficerName = compHouseOfficerName.replace(salutation, '').trim();
                            });

                            compHouseOfficerName = compHouseOfficerName.replace(/,+$/, '');

                            if(compHouseOfficerName.includes(', ')){
                                let nameSplit = compHouseOfficerName.split(', ');
                                let newNameArr = nameSplit.length > 1 ? nameSplit.slice(1, nameSplit.length) : [];
                                newNameArr.push(nameSplit[0]);
                                compHouseOfficerName = newNameArr.join(' ');
                            }
                            
                            if (contactListObj.Name != compHouseOfficerName) {
                                mismatchRow.mismatchedFields.push({
                                    mismatchId : mismatchRow.sfId+'-Full Name',
                                    fieldApi : 'Name',
                                    fieldName : 'Full Name',
                                    sfRbId : this.makeId(),
                                    sfValue : contactListObj.Name,
                                    compRbId : this.makeId(),
                                    compHouseValue : compHouseOfficerName
                                });
                            }

                            console.log('state.Name:: ' + compHouseOfficerName);
                            
                            //MISMATCH OFFICER ROLE
                            if (contactListObj.Title != state.officerData.officer_role) {
                                mismatchRow.mismatchedFields.push({
                                    mismatchId : mismatchRow.sfId+'-OfficerRole',
                                    fieldApi : 'Title',
                                    fieldName : 'Title',
                                    sfRbId: this.makeId(),
                                    sfValue : contactListObj.Title,
                                    compRbId: this.makeId(),
                                    compHouseValue : state.officerData.officer_role
                                });
                            }
                            console.log('state.officerData.officer_role:: ' + state.officerData.officer_role);
                            
                            //MISMATCH COUNTRY OF RESIDENCE
                            let residentCountry = state.officerData.country_of_residence;
                            if(!residentCountry && personData){
                                residentCountry = personData.country_of_residence;
                            }
                            if (contactListObj.Resident_Country__c != residentCountry) {
                                mismatchRow.mismatchedFields.push({
                                    mismatchId : mismatchRow.sfId+'-ResidenceCountry',
                                    fieldApi : 'Resident_Country__c',
                                    fieldName : 'Resident Country',
                                    sfRbId : this.makeId(),
                                    sfValue : contactListObj.Resident_Country__c,
                                    compRbId : this.makeId(),
                                    compHouseValue : residentCountry
                                });
                            }
                            console.log('residentCountry:: ' + residentCountry);

                            //MISMATCH NATIONALITY
                            let nationality = state.officerData.nationality;
                            if(!nationality && personData){
                                nationality = personData.nationality;
                            }
                            if (contactListObj.Nationality__c != nationality) {
                                mismatchRow.mismatchedFields.push({
                                    mismatchId : mismatchRow.sfId+'-Nationality',
                                    fieldApi : 'Nationality__c',
                                    fieldName : 'Nationality',
                                    sfRbId: this.makeId(),
                                    sfValue : contactListObj.Nationality__c,
                                    compRbId: this.makeId(),
                                    compHouseValue : nationality
                                });
                            }
                            console.log('nationality::' + nationality);

                            //MISMATCH OCCUPATION 
                            // let contactOccupation = contactListObj.Description != null && contactListObj.Description != "undefined" ? contactListObj.Description : undefined;
                            // if (contactOccupation != state.officerData.occupation) {
                            //     mismatchRow.mismatchedFields.push({
                            //         mismatchId : mismatchRow.sfId+'-Occupation',
                            //         fieldApi : 'Description',
                            //         fieldName : 'Occupation',
                            //         sfRbId: this.makeId(),
                            //         sfValue : contactOccupation,
                            //         compRbId: this.makeId(),
                            //         compHouseValue : state.officerData.occupation
                            //     });
                            // }
                            console.log('state.officerData.occupation:: ' + state.officerData.occupation);

                            //MAILING STREET
                            let street = personData?.address?.address_line_1;
                            if(contactListObj.MailingStreet != street){
                                mismatchRow.mismatchedFields.push({
                                    mismatchId : mismatchRow.sfId+'-MailingStreet',
                                    fieldApi : 'MailingStreet',
                                    fieldName : 'Mailing Street',
                                    sfRbId : this.makeId(),
                                    sfValue : contactListObj.MailingStreet,
                                    compRbId : this.makeId(),
                                    compHouseValue : street
                                });
                            }

                            //MAILING CITY
                            let city = personData?.address?.address_line_2;
                            if(contactListObj.MailingCity != city){
                                mismatchRow.mismatchedFields.push({
                                    mismatchId : mismatchRow.sfId+'-MailingCity',
                                    fieldApi : 'MailingCity',
                                    fieldName : 'Mailing City',
                                    sfRbId : this.makeId(),
                                    sfValue : contactListObj.MailingCity,
                                    compRbId : this.makeId(),
                                    compHouseValue : city
                                });
                            }
                            //MAILING STATE
                            let stateVal = personData?.address?.locality;
                            if(contactListObj.MailingState != stateVal){
                                mismatchRow.mismatchedFields.push({
                                    mismatchId : mismatchRow.sfId+'-MailingState',
                                    fieldApi : 'MailingState',
                                    fieldName : 'Mailing State',
                                    sfRbId : this.makeId(),
                                    sfValue : contactListObj.MailingState,
                                    compRbId : this.makeId(),
                                    compHouseValue : stateVal
                                });
                            }
                            
                            let country = personData?.address?.country;
                            //MAILING COUNTRY
                            if(contactListObj.MailingCountry != country){
                                mismatchRow.mismatchedFields.push({
                                    mismatchId : mismatchRow.sfId+'-MailingCountry',
                                    fieldApi : 'MailingCountry',
                                    fieldName : 'Mailing Country',
                                    sfRbId : this.makeId(),
                                    sfValue : contactListObj.MailingCountry,
                                    compRbId : this.makeId(),
                                    compHouseValue : country
                                });
                            }
                            
                            //MAILING POSTAL CODE
                            let postalCode = personData?.address?.postal_code;
                            if(contactListObj.MailingPostalCode != postalCode){
                                mismatchRow.mismatchedFields.push({
                                    mismatchId : mismatchRow.sfId+'-MailingPostalCode',
                                    fieldApi : 'MailingPostalCode',
                                    fieldName : 'Mailing Postal Code',
                                    sfRbId : this.makeId(),
                                    sfValue : contactListObj.MailingPostalCode,
                                    compRbId : this.makeId(),
                                    compHouseValue : postalCode
                                });
                            }

                            //BIRTH DATE 
                            const sfbirthDate = new Date(contactListObj.Birthdate);
                            const sfBirthMonth = sfbirthDate != 'Invalid Date' && sfbirthDate != 'NaN' ? sfbirthDate.toLocaleDateString('en-US', { month: 'short' }) : undefined;
                            const sfBirthYear = sfbirthDate != 'Invalid Date' && sfbirthDate != 'NaN' ? sfbirthDate.getFullYear().toString() : undefined;

                            const chYear = state.officerData.date_of_birth?.year ? state.officerData.date_of_birth?.year.toString() : undefined;
                            const chMonth = state.officerData.date_of_birth?.month;
                            const chFormatteddBirthday = new Date(Date.UTC(chYear, chMonth - 1, 1)); 
                            const chBirthMonth = chFormatteddBirthday != 'Invalid Date' && chFormatteddBirthday != 'NaN' ? chFormatteddBirthday.toLocaleDateString('en-US', { month: 'short' }) : undefined;
                            
                            // const birthDate = new Date(contactListObj.Birthdate); 
                            // const sfBirthMonth = (birthDate.getMonth() + 1).toString(); //Date_of_Birth_Month__c
                            // const sfBirthYear = birthDate.getFullYear().toString(); //Date_of_Birth_Year__c
                            
                            // const chYear = state.officerData.date_of_birth.year;
                            // const chMonth = state.officerData.date_of_birth.month;

                            // const sfFormatteddBirthday = new Date(contactListObj.Birthdate);
                            // const chFormatteddBirthday = new Date(Date.UTC(chYear, chMonth - 1, 1));

                            // const sfbirthDate = sfFormatteddBirthday.toLocaleDateString('en-US', { month: 'short', day: '2-digit', year: 'numeric' });
                            // const chBirthdate = chFormatteddBirthday.toLocaleDateString('en-US', { month: 'short', day: '2-digit', year: 'numeric' });


                            //MISMATCH MONTH OF BIRTH
                            if (sfBirthMonth != chBirthMonth) {
                                mismatchRow.mismatchedFields.push({
                                    mismatchId : mismatchRow.sfId+'-BirthMonth',
                                    fieldApi : 'Date_of_Birth_Month__c',
                                    fieldName : 'Birth Month',
                                    sfRbId: this.makeId(),
                                    sfValue : sfBirthMonth,
                                    compRbId: this.makeId(),
                                    compHouseValue : chBirthMonth
                                });
                            }
                            //console.log('state.officerData.date_of_birth.month:: ' + state.officerData.date_of_birth.month);

                            //MISMATCH YEAR OF BIRTH
                            if (sfBirthYear != chYear) {
                                mismatchRow.mismatchedFields.push({
                                    mismatchId : mismatchRow.sfId+'-BirthYear',
                                    fieldApi : 'Date_of_Birth_Year__c',
                                    fieldName : 'Birth Year',
                                    sfRbId: this.makeId(),
                                    sfValue : sfBirthYear,
                                    compRbId: this.makeId(),
                                    compHouseValue : chYear
                                });
                            }
                            console.log('state.officerData.date_of_birth.year:: ' + state.officerData.date_of_birth?.year);
                            
                            if(mismatchRow.mismatchedFields.length > 0){
                                mismatchRow.hasConflict = true;
                            } else {
                                mismatchRow.hasConflict = false;
                            }

                            this.mismatchFields.push(mismatchRow);
                        }
                    });

                    
                    // if(this.mismatchFields.mismatchRow.length === 0 || this.mismatchFields.mismatchRow == []){
                    //     console.log('No conflicts found!');
                    //     this.showToast('Success!', 'No conflicts found. Please proceed to the next step', 'success', 'dismissable');
                    // } else {
                    //     this.showToast('Success!', 'Mismatch Information Found.', 'success', 'dismissable');
                    // }
                   
                    console.log('this.mismatchFields:: '  + JSON.stringify(this.mismatchFields));
                }
                
                const allRecordsHaveNoConflict = this.mismatchFields.every(record => !record.hasConflict);
                if (allRecordsHaveNoConflict) {
                    this.isLoading = false;
                    this.matchHasNoConflict = true;
                } else {
                    this.isLoading = false;
                    this.matchHasNoConflict = false;
                }
                console.log('this.matchHasNoConflict:: ' + this.matchHasNoConflict);

            }).catch(error => {
                console.log('An error has occurred');
                this.isLoading = false;
                this.allSelectedContactList = undefined;
                this.showToast('Error!', 'An error has occured. Error: '+ error.body.message, 'error', 'dismissable');
                console.log('Error upon merging:: ' + JSON.stringify(error));
            });
        }).catch(error => {
            this.isLoading = false;
            this.allSelectedContactList = undefined;
            this.showToast('Error!', 'An error has occured. Error: '+ error.body.message, 'error', 'dismissable');
            console.log('Error upon creation of contact :: ' + JSON.stringify(error));
        });
    }

    //STEP 3 : HANDLES CREATION OF UNIQUE ID
    makeId(){
        return "rbid-" + Math.random().toString(16).slice(2);
    }

    //STEP 3 : HANDLE COMPACT LAYOUT ON MOUSEOVER
    handleMouseover(event) {
        const toolTipDiv = this.template.querySelector('div.ModelTooltip_' + event.currentTarget.dataset.officerKey + event.currentTarget.dataset.recordId);
        toolTipDiv.style.opacity = 1;
        toolTipDiv.style.display = "block";
        window.clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(() => {
            this.objRecordId = this.recordId;
        }, 150);
    }

    //STEP 3 : HANDLE COMPACT LAYOUT ON MOUSEOUT
    handleMouseout(event) {
        const toolTipDiv = this.template.querySelector('div.ModelTooltip_' + event.currentTarget.dataset.officerKey + event.currentTarget.dataset.recordId);
        toolTipDiv.style.opacity = 0;
        toolTipDiv.style.display = "none";
    }

    //STEP 4 : HANDLE SELECT ALL SFVALUE OR COMPANIES HOUSE VALUES
    handleSelectAllChange(event){
        const originalRadioBtn = event.target.id;
        let contactId = event.currentTarget.dataset.contactId;
        const conRadioButtons = this.template.querySelectorAll(`input.contactFields[data-contact-id="${contactId}"]`);
        const chRadioButtons = this.template.querySelectorAll(`input.companiesHouseFields[data-contact-id="${contactId}"]`);

        const lastHyphenIndex = originalRadioBtn.lastIndexOf('-');
        const radioBtnId = originalRadioBtn.substring(0, lastHyphenIndex);
        console.log('radioBtnId:: ' + radioBtnId);

        if(radioBtnId == 'selectedAllSFValues-' + contactId) {
            conRadioButtons.forEach((radioButton) => {
                radioButton.checked = true;
            });
            chRadioButtons.forEach((radioButton) => {
                radioButton.checked = false; // Deselect Companies House radio buttons
            });
        } else if(radioBtnId == 'selectedAllCHValues-' + contactId) {
            chRadioButtons.forEach((radioButton) => {
                radioButton.checked = true;
            });
            conRadioButtons.forEach((radioButton) => {
                radioButton.checked = false; // Deselect Contact radio buttons
            });
        }

        let selectedValues = [];
        let fieldApiNames = [];
        for (const radioButton of conRadioButtons) {
            if (radioButton.checked && radioButton.value != null && radioButton.value !== 'undefined' && radioButton.value !== undefined) {
                selectedValues.push(radioButton.value);
            } else {
                selectedValues.push(null);
            }

            let fieldApiName = radioButton.getAttribute('data-api-name');
            fieldApiNames.push(fieldApiName);
        }

        for (const radioButton of chRadioButtons) {
            if (radioButton.checked && radioButton.value != null && radioButton.value != 'undefined' && radioButton.value !== undefined) {
                selectedValues.push(radioButton.value);
            } else {
                selectedValues.push(null);
            }

            let fieldApiName = radioButton.getAttribute('data-api-name');
            fieldApiNames.push(fieldApiName);
        }

        let mismatchRow = this.mismatchFields.find(mismatchField => mismatchField.sfId == contactId);
        
        let contact = (this.contactsToUpdate.find(cont => cont.Id == contactId) ? this.contactsToUpdate.find(cont => cont.Id == contactId) : { Id: contactId, Officer_Key__c: mismatchRow.sfOfficerKey });
        // let contact = (this.contactsToUpdate.find(cont => cont.Id == contactId) ? this.contactsToUpdate.find(cont => cont.Id == contactId) : { Id: contactId });
        fieldApiNames.forEach((fieldApiName, index) => {
            contact[fieldApiName] = selectedValues[index];
        });

        if(!contact.Name){
            let contFound = this.allSelectedContactList.find(cont => cont.Id == contact.Id);
            contact.Name = contFound.Name;
        }

        let index = this.contactsToUpdate.findIndex(cont => cont.Id == contactId);

        if(index >= 0){
            this.contactsToUpdate[index] = contact;
        } else {
            this.contactsToUpdate.push(contact);
        }

        console.log('contactsToUpdate after');
        console.log(JSON.stringify(this.contactsToUpdate));

        this.getFieldApiNamesAndValues();
    }

    //STEP 4 : HANDLE CONFLICT
    conflictOnChangeContact(event){
        let contactId = event.currentTarget.dataset.contactId;
        //let selectedMismatchName = event.target.name;
        let fieldApiName = event.currentTarget.dataset.apiName;
        let selectedValue = event.target.value;

        if(selectedValue === 'true'){
            selectedValue = true;
        } else if(selectedValue === 'false'){
            selectedValue = false;
        }

        let mismatchRow = this.mismatchFields.find(mismatchField => mismatchField.sfId == contactId);
        console.log('mismatchRow');
        console.log(mismatchRow);

        console.log('contactsToUpdate before');
        console.log(JSON.stringify(this.contactsToUpdate));

        let contact = (this.contactsToUpdate.find(cont => cont.Id == contactId) ? this.contactsToUpdate.find(cont => cont.Id == contactId) : { Id: contactId, Officer_Key__c: mismatchRow.sfOfficerKey });
        // let contact = (this.contactsToUpdate.find(cont => cont.Id == contactId) ? this.contactsToUpdate.find(cont => cont.Id == contactId) : { Id: contactId });
        contact[fieldApiName] = selectedValue;
        
        if(!contact.Name){
            let contFound = this.allSelectedContactList.find(cont => cont.Id === contact.Id);
            contact.Name = contFound.Name;
        }

        let index = this.contactsToUpdate.findIndex(cont => cont.Id == contactId);
        console.log('index:' + index);

        if(index >= 0){
            this.contactsToUpdate[index] = contact;
        } else {
            this.contactsToUpdate.push(contact);
        }

        console.log('contactsToUpdate after');
        console.log('this.contactsToUpdate:: ' + JSON.stringify(this.contactsToUpdate));

        // this.getFieldApiNamesAndValues();
    }

    //STEP 4 : GETS FIELD API NAME, FIELD VALUE OF CONTACTS WITH CONFLICT W COMPANIES HOUSE DATA
    async getFieldApiNamesAndValues(){
        // let forReview = {};
        // const promises = [];
        // for(let item of this.contactsToUpdate){
        //     console.log('item::' + JSON.stringify(item));
        //     for (const key in item) {
        //         if (key !== "Id") {
        //             console.log('key::' + JSON.stringify(key));

        //             if (!forReview[item.Id]) {
        //                 forReview[item.Id] = {
        //                   Id: item.Id,
        //                   FullName: item.Name,
        //                   FieldsToReview: []
        //                 };
        //             }
    
        //             const promise = this.getFieldLabel(key).then(fieldLabel => {
        //                 const newItem = {
        //                     ApiId: item.Id + '-' + key,
        //                     ApiName: key,
        //                     ApiLabel: fieldLabel,
        //                     Value: item[key]
        //                 };
                    
        //                 forReview[item.Id].FieldsToReview.push(newItem);
        //             });
        //             promises.push(promise);
        //         }
        //     }
        // }

        // await Promise.all(promises);
        // this.allContactsForReview = Object.values(forReview);
        // console.log('this.allContactsForReview' + JSON.stringify(this.allContactsForReview));
        // this.isLoading = true;
        const forReviewExisting = {};
        const forReviewFiltered = {};
        const promises = [];

        const processContact = async (contact, forReview) => {
            if(!contact.Name){
                let contFound = this.allSelectedContactList.find(cont => cont.Id === contact.Id);
                contact.Name = contFound.Name;
            }

            if (!forReview[contact.Id]) {
                forReview[contact.Id] = {
                    Id: contact.Id,
                    FullName: contact.Name,
                    FieldsToReview: []
                };
            }

            for (const key in contact) {
                if (key !== "Id" && key !== "Officer_Key__c" && key != "AccountId" && key != 'Account') {
                    const fieldLabel = await this.getFieldLabel(key);
                    let formattedValue = contact[key];

                    if (key === "Date_of_Birth_Month__c") {
                        // Format Birthdate
                        formattedValue = new Date(Date.parse(`01/${contact["Date_of_Birth_Month__c"]}/2000`)).toLocaleDateString('en-US', { month: 'short' });
                    }

                    if (key === "Birthdate") {
                        // Format Birthdate
                        const birthdate = new Date(contact[key]);
                        formattedValue = birthdate.toLocaleDateString('en-US', {month: 'short', day: '2-digit', year: 'numeric'});
                    }

                    const newItem = {
                        ApiId: contact.Id + '-' + key,
                        ApiName: key,
                        ApiLabel: fieldLabel,
                        Value: formattedValue
                    };

                    forReview[contact.Id].FieldsToReview.push(newItem);
                }
            }

            await Promise.all(promises);
        };

        await Promise.all(this.contactsToUpdate.map(contact => processContact(contact, forReviewExisting)));
        await Promise.all(this.createdContacts.map(contact => processContact(contact, forReviewExisting)));

        const existingContactIds = Object.keys(forReviewExisting);
        const filteredContactsToUpdate = this.allSelectedContactList.filter(contact => !existingContactIds.includes(contact.Id));
        
        await Promise.all(filteredContactsToUpdate.map(contact => processContact(contact, forReviewFiltered)));

        this.allContactsForReview = Object.values({ ...forReviewExisting, ...forReviewFiltered });
        // if(this.allContactsForReview.length != 0){
            // this.isLoading = false;
            // this.disableFinishBtn = false;
        // }
        console.log('this.allContactsForReview' + JSON.stringify(this.allContactsForReview));
    }

    //STEP 4 : GETS FIELD LABEL OF CONTACTS WITH CONFLICT W COMPANIES HOUSE DATA
    async getFieldLabel(fieldApiName){
        try {
            console.log('fieldApiName', fieldApiName);
            const result = await getOfficerFieldNameAndAPI({ 
                fieldApiName : fieldApiName 
            });
            console.log('result fieldLabel:: ' + result);
            return result;
        } catch (error) {
            console.log('Field Label Not Found Error :: ' + JSON.stringify(error));
            return '';
        }
    }

    //STEP 5 : HANDLES EXPANDABLE SECTION OF ITEMS FOR REVIEW
    toggleExplandableSection(event) {
        let buttonid = event.currentTarget.dataset.buttonid;
        let currentsection = this.template.querySelector('[data-id="' + buttonid + '"]');
        if (currentsection.className.search('slds-is-open') === -1) {
            currentsection.className = 'slds-section slds-is-open';
        } else {
            currentsection.className = 'slds-section slds-is-close';
        }
    }

    //STEP 5 : FINISH BUTTON VISIBILITY
    get isSelectStep7() {
        return this.selectedStep === "Step7";
    }

    //TOAST EVENT
    async showToast(title, message, variant, mode){
        const toastEvent = new ShowToastEvent({
            "title": title,
            "message": message,
            "variant": variant,
            "mode": mode
        });
        this.dispatchEvent(toastEvent);
    }

    handleImportPSC(event){
        let value   = event.currentTarget.value,
            id      = event.currentTarget.dataset.identifier;

        console.log('value value value => ', value);
        console.log('id id id => ', id);

        let newPSCDataActive = [];
        this.pscData.forEach( item => {
            if( id == item.Id ){
                item.importData.donotimport = value == 'doNotImport';
                item.importData.isNew       = value == 'createNew';
                item.importData.isMatch     = value == 'searchExisting';
            }
            newPSCDataActive.push(item)
        });
        console.log('newPSCDataActive newPSCDataActive newPSCDataActive', newPSCDataActive);
        this.pscData  = newPSCDataActive;
    }

    handleRecordSelect(event){
        let selectedRecord = event.currentTarget.value,
            id  = event.currentTarget.dataset.identifier;

        let newPSCDataActive = [];
        this.pscData.forEach( item => {
            if( id == item.Id ){
                item.isSelectedRecord = selectedRecord;
            }
            newPSCDataActive.push(item)
        });
        this.pscData  = newPSCDataActive;
    }
}