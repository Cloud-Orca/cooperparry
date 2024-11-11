import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import executeRequest from '@salesforce/apex/GetBeauhurstCompanies.callBatch';
import getTotal from '@salesforce/apex/GetBeauhurstCompanies.getTotal';

export default class GetCompanies extends LightningElement {
    collectionId;
    showResults = false;
    total       = 0;
    showSpinner = false;

    onCancel(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    onPrevious(){
        this.showResults = false;
    }

    onConfirmSync(){
        if( this.collectionId != '' && this.collectionId != null ){
            console.log('Call Apex Class');
            executeRequest({collectionId : this.collectionId})
            .then( result => {  
                this.showToast('Info', 'Record is currently syncing.', 'info', 'dismissable');
                this.onCancel();
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
            getTotal({collectionId : this.collectionId})
            .then( result => { 
                console.log('result', result); 
                this.total          = result.meta.total == null ?  0 : result.meta.total;
                
                // window.setTimeout(() => { 
                    this.showSpinner    = false;
                // }, 2000);
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