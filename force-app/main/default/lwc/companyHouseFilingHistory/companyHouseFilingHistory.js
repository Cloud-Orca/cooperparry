import { LightningElement, api, track } from 'lwc';
import getCompanyName from '@salesforce/apex/CompanyHouseFilingHistoryCont.getCompanyName';
import getCompanyNumber from '@salesforce/apex/CompanyHouseFilingHistoryCont.getCompanyNumber';
import getFilingHistory from '@salesforce/apex/CompanyHouseFilingHistoryCont.getFilingHistory';

export default class CompanyHouseFilingHistory extends LightningElement {
    @track filingHistoryData = [];
    @api recordId;
    @track compName;
    @track compNumber;
    isRenderedCallBack = false;

    filingHistoryColumns = [
        { 
            label: 'Date', fieldName: 'date', 
        },
        { 
            label: 'Type', fieldName: 'type',
        },
        { 
            label: 'Description', fieldName: 'description',
        },
        { 
            label: 'View/Download', fieldName: 'websiteUrl', type: 'url',
            typeAttributes: {
                label: { fieldName:'fileLabel' }
            }
        }
    ];

    connectedCallback(){
        this.getCompNumber();
        // this.getCompName();
    }

    getCompNumber(){
        getCompanyNumber({
            recordId : this.recordId
        }).then( result => {   
            this.compNumber = result;
            if(this.compNumber != null){
                this.getFilingHistory(this.compNumber);
            }
        }).catch(error => {
            console.log('Error '+JSON.stringify(error));
        });
    }

    getCompName(){
        getCompanyName({
            recordId : this.recordId
        }).then( result => {   
            this.compName = result;
            console.log('Company Name:: ' + this.compName);

            if(this.compName != null){
                this.getFilingHistory(this.compName);
            }
        }).catch(error => {
            console.log('Error '+JSON.stringify(error));
        });
    }

    getFilingHistory(companyHouseName){
        getFilingHistory({
            companyHouseName : companyHouseName
        }).then( result => {   
           if(result){
                console.log(result);
                this.filingHistoryData = [];
                var fHistoryData = JSON.parse(JSON.stringify(this.filingHistoryData));
                if(result.isFound){
                    result.items.forEach(function(e){
                        var date = e.actionDate != null ? e.actionDate : null;
                        var type = e.type != null ? e.type : null;
                        var descrip = e.description != null ? (e.description).charAt(0).toUpperCase() + (e.description).slice(1) : null;
                        var url = e.downloadURL != null ? e.downloadURL : null;

                        fHistoryData.push({
                            date: date,
                            type: type,
                            description: descrip,
                            fileLabel: 'View PDF',
                            websiteUrl : url
                        });
                    });
                    this.filingHistoryData = fHistoryData;
                }
           }
        }).catch(error => {
            console.log('Error '+JSON.stringify(error));
        });
    }
}