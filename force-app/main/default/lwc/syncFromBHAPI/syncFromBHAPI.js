import { LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import {CurrentPageReference} from 'lightning/navigation';
import executeRequest from '@salesforce/apex/BeauhurstAPIUtility.updateFromBH';

export default class SyncFromBHAPI extends LightningElement {
    _recordId;
    isSpinner = false;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this._recordId = currentPageReference.state.recordId;
        }
    }

    connectedCallback(){
        console.log('this._recordId', this._recordId);
        this.isSpinner = true;
        setTimeout(() => {
            executeRequest({accId : this._recordId})
            .then( result => {  
                console.log('result', result);
                if(result.success){
                    this.showToastMessage('Success', 'Account successfully updated.', 'success');
                    setTimeout(() => {
                        window.location.reload();
                    }, 1000); 
                }else{
                    this.showToastMessage('API Error', result.errorMsg, 'error');
                }
                this.isSpinner = false;
                this.dispatchEvent(new CloseActionScreenEvent());
            }).catch(error => {
                console.log('Error '+JSON.stringify(error));
            }); 
        }, 3000);
    }

    showToastMessage(title, message, variant) {
        const evt = new ShowToastEvent({ title, message, variant, mode: 'dismissable'});
        this.dispatchEvent(evt);
    }
}