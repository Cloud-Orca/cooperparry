import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import syncRecord from '@salesforce/apex/GetBeauhurstCompanies.syncRecord';
import getCollectionDetail from '@salesforce/apex/GetBeauhurstCompanies.getCollectionDetail';

export default class GetCompanies extends LightningElement {
    collectionId;
    showResults = false;
    total       = 0;
    showSpinner = false;
    detail = {};

    onCancel(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    onPrevious(){
        this.showResults = false;
    }

    onConfirmSync(){
        if( this.collectionId != '' && this.collectionId != null ){
            console.log('Call Apex Class');
            this.showSpinner = true;
            syncRecord({params : this.detail})
            .then( result => { 
                console.log('result result ' + result); 
                if( result.isSuccess ){
                    this.showToast('Success', result.message, 'success', 'dismissable');
                    this.collectionId = '';
                } else {
                    this.showToast('Error', result.message, 'error', 'dismissable');
                }

                this.showSpinner = false;
                this.showResults = false;
            }).catch(error => {
                console.log('Error '+JSON.stringify(error));
            }); 
        }
    }

    onProceed(){
        this.collectionId = this.template.querySelector('lightning-input').value;
        console.log('this.collectionId', this.collectionId);

        if( this.collectionId != '' && this.collectionId != null ){
            this.showSpinner = true;
            this.showResults = true;
            getCollectionDetail({collectionId : this.collectionId})
            .then( result => { 
                console.log('result', result); 
                if( result.isExist ){ 
                    this.showToast('Error', 'Collection Id has already existing Company Collection record.', 'error', 'dismissable');
                    this.showResults = false;
                } else {
                    if( result.resDetails.length > 0 ){
                        this.detail = result.resDetails[0];
                    } else {
                        this.showResults = false;
                        this.showToast('Error', 'Can\'t find any record for this collection Id : ' + this.collectionId, 'error', 'dismissable');
                    }
                }
                this.showSpinner    = false;
            }).catch(error => {
                console.log('Error '+JSON.stringify(error));
            }); 
        } else {
            this.showToast('Error', 'Input field must not be empty', 'error', 'dismissable');
        }
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