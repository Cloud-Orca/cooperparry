import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getNumberOfRows from '@salesforce/apex/CSVRecordUploaderController.getNumberOfRows';
import createRecord from '@salesforce/apex/CSVRecordUploaderController.createRecord';



export default class CSVRecordUploader extends LightningElement {
    @track errorMessage;
    @track isLoading = false;
    @track isFileAdded = false;
    @track successFile;
    @track errorFile;
    @track isSubmitted = false;
    @track numberOfErrors = 0;
    @track numberOfSuccess = 0;
    @track multiplesuccessFile = false;
    @track multipleerrorFile = false;
    @track multiplesuccessFileTxt = {};
    @track multipleerrorFileTxt = {};
    fileContents;
    numberOfRows = 0;
    pageName;
    label;

    @wire(CurrentPageReference)
    wiredCurrentPageReference(currentPageReference) {
        // console.log(currentPageReference?.attributes?.apiName);
        this.pageName = currentPageReference?.attributes?.apiName;
        if(this.pageName == 'Lead_Uploader'){
            this.label = 'Lead';
        }
        if(this.pageName == 'Account_Uploader'){
            this.label = 'Account';
        }
        if(this.pageName == 'Contact_Uploader'){
            this.label = 'Contact';
        }
    }

    async handleFileChange(event) {
        try{
            const file = event.target.files[0];
            if (file && file.type === 'text/csv') {
                await this.readFile(file);
                // console.log('@@@ fileContents 1: ' + this.fileContents);
                // let numRows = await getNumberOfRows({ csvData: this.fileContents });
                // console.log(numRows);
            } else {
                this.errorMessage = 'Please upload a valid CSV file.';
            }
        }catch(error){
            console.log(error);
        }
    }

    async readFile(file) {
        // console.log('@@@ readFile');
        const reader = new FileReader();
        reader.onload = () => {
            this.fileContents = reader.result;
            this.errorMessage = null;
            this.isFileAdded = true;
            this.isSubmitted = false;
            this.getNumberOfRows();
        };
        reader.onerror = () => {
            this.errorMessage = 'Error reading file';
        };
        reader.readAsText(file);
    }


    async getNumberOfRows(){
        try{
            console.log('@@@ fileContents 1: ' + this.fileContents);
            let numRows = await getNumberOfRows({ csvData: this.fileContents });
            if(numRows){
                this.numberOfRows = numRows - 1;
            }
        }catch(error){
            console.log(error);
        }
    }

    handleSubmit() {
        if (this.fileContents) {
            this.isLoading = true;
            if (this.pageName == 'Lead_Uploader' || this.pageName == 'Account_Uploader' || this.pageName == 'Contact_Uploader') {
                try {
                    var objName;
                    if (this.pageName == 'Lead_Uploader') {
                        objName = 'Lead';
                    }else if (this.pageName == 'Account_Uploader') {
                        objName = 'Account';
                    }else if (this.pageName == 'Contact_Uploader') {
                        objName = 'Contact';
                    }
                    createRecord({ csvData: this.fileContents, obj: objName }).then(result => {
                        this.isLoading = false;
                        if (result.successFile) {
                            this.successFile = result.successFile;
                            this.numberOfSuccess = this.successFile.split('\n').length - 2; // skip first 2 lines
                        }
                        if (result.errorFile) {
                            this.errorFile = result.errorFile;
                            this.numberOfErrors = this.errorFile.split('\n').length - 2; // skip first 2 lines
                        }
                        this.isSubmitted = true;
                    })
                    .catch(error => {
                        this.isSubmitted = false;
                        this.isLoading = false;
                        this.errorMessage = 'Error creating records: ' + error.body.message;
                    });
                } catch (error) {
                    console.log(error);
                }
            }


        } else {
            this.errorMessage = 'Please upload a CSV file first.';
        }
    }


    downloadSuccessFile() {
        this.downloadFile(this.successFile, 'SuccessFile.csv');
    }

    downloadErrorFile() {
        this.downloadFile(this.errorFile, 'ErrorFile.csv');
    }

    downloadFile(fileContent, fileName) {
        const element = document.createElement('a');
        const file = new Blob([fileContent], { type: 'text/plain' });
        element.href = URL.createObjectURL(file);
        element.download = fileName;
        document.body.appendChild(element);
        element.click();
        document.body.removeChild(element);
    }


    downloadSuccessFileMultiple(){
        this.downloadFiles(this.multiplesuccessFileTxt);
    }
    downloadErrorFileMultiple(){
        this.downloadFiles(this.multipleerrorFileTxt);
    }

    downloadFiles(fileContent) {
        for (const key in fileContent) {
            const filecont = fileContent[key];
            const element = document.createElement('a');
            const file = new Blob([filecont], { type: 'text/plain' });
            element.href = URL.createObjectURL(file);
            element.download = key + '.csv';
            document.body.appendChild(element);
            element.click();
            document.body.removeChild(element);
        }
    }

    
}