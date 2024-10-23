import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPathDriveItems from '@salesforce/apex/SharepointCompCont.getPathDriveItems';
import getDriveItemId from '@salesforce/apex/SharepointCompCont.getDriveItemId';
import getChildrenFromDriveId from '@salesforce/apex/SharepointCompCont.getChildrenFromDriveId';
import uploadDocument from '@salesforce/apex/SharepointCompCont.uploadDocument';
import getSecurePublicGroup from '@salesforce/apex/SharepointCompCont.getSecurePublicGroup';

export default class SharepointComp extends LightningElement {
    @api recordId;
    isSpinner = false;

    @track breadcrumbs = [{ label: 'Documents', id: 'root' }];
    @track currentItems = [];

    @track rootItems = [];
    fileDataListFinal = [];
    @track driveItemId;
    originalDriveItemId;

    showDriveItemBlank = false;
    isUserInSecureGroup;

    async connectedCallback() {
        this.isSpinner = true;
        const isUserInSecureGroup = await getSecurePublicGroup({});
        console.log(isUserInSecureGroup);
        this.isUserInSecureGroup = isUserInSecureGroup;

        this.getPathDriveItems();
        this.getDriveItemId();
    }

    async getDriveItemId(){
        try{
            let driveItemID = await getDriveItemId({recordId: this.recordId});
            console.log('@@@ driveItemID: ' + driveItemID);
            if(driveItemID == null){
                this.showDriveItemBlank = true;
            }
        }catch(error){
            this.isSpinner = false;
            console.error(error);
        }
    }

    async getPathDriveItems(){
        try{
            console.log(this.recordId);
            let driveItemList = await getPathDriveItems({recordId: this.recordId});
            console.log(driveItemList);

            let self = this;
            let driveItemId;
            let finaldriveItemList = [];
            let isUserInSecureGroup = this.isUserInSecureGroup;
            if(driveItemList){
                driveItemList.forEach(function(driveItem){
                    driveItem.iconName = (driveItem.isFolder) ? 'doctype:folder' : self.getIconName(driveItem.name);
                    driveItemId =  driveItem.currentDriveItemId;

                    if(driveItem.name == 'Secure Folder' && !isUserInSecureGroup) {
                        return;
                    }
                    finaldriveItemList.push(driveItem);
                });
            }
            
            this.rootItems = finaldriveItemList;
            this.currentItems = finaldriveItemList;
            this.driveItemId = driveItemId;
            this.originalDriveItemId = driveItemId;
            console.log('@@@ this.driveItemId: ' + this.driveItemId);
            this.isSpinner = false;
        }catch(error){
            this.isSpinner = false;
            console.error(error);
        }
    }

    async handleItemClick(event) {
        const itemId = event.currentTarget.dataset.id;
        const selectedItem = this.currentItems.find(item => item.id === itemId);
        this.driveItemId = selectedItem.id;

        console.log('@@@ this.driveItemId: ' + this.driveItemId);

        if (selectedItem && selectedItem.isFolder) {
            this.breadcrumbs.push({ label: selectedItem.name, id: selectedItem.id });

            try{
                this.isSpinner = true;
                console.log(this.recordId);
                let driveItemList = await getChildrenFromDriveId({driveItemId: selectedItem.id, recordId: this.recordId});
                console.log(driveItemList);

                let self = this;
                if(driveItemList){
                    driveItemList.forEach(function(driveItem){
                        driveItem.iconName = (driveItem.isFolder) ? 'doctype:folder' : self.getIconName(driveItem.name);
                    });
                }
                this.isSpinner = false;
                this.currentItems = driveItemList;
            }catch(error){
                this.isSpinner = false;
                console.error(error);
            }
        }
        else{
            window.open(selectedItem.webUrl);
        }
    }

    async handleBreadcrumbClick(event) {
        const index = event.currentTarget.dataset.index;
        this.breadcrumbs = this.breadcrumbs.slice(0, parseInt(index) + 1);

        if (index == 0) {
            this.currentItems = this.rootItems;
            this.driveItemId = this.originalDriveItemId; 
        } else {
            const folderId = this.breadcrumbs[index].id;
            this.driveItemId = folderId;
            try{
                this.isSpinner = true;
                let driveItemList = await getChildrenFromDriveId({driveItemId: folderId});

                let self = this;
                if(driveItemList){
                    driveItemList.forEach(function(driveItem){
                        driveItem.iconName = (driveItem.isFolder) ? 'doctype:folder' : self.getIconName(driveItem.name);
                    });
                }

                console.log(driveItemList);
                this.currentItems = driveItemList;

                this.isSpinner = false;
            }catch(error){
                this.isSpinner = false;
                console.error(error);
            }
        }
        console.log('@@@ this.driveItemId: ' + this.driveItemId);
    }

    getIconName(fileName){
        fileName = fileName.toLowerCase(); // Convert the filename to lowercase
        if (fileName.includes('.doc') || fileName.includes('.docx')) {
            return 'doctype:word';
        } else if (fileName.includes('.xls') || fileName.includes('.xlsx')) {
            return 'doctype:excel';
        } else if (fileName.includes('.ppt') || fileName.includes('.pptx')) {
            return 'doctype:ppt';
        } else if (fileName.includes('.pdf')) {
            return 'doctype:pdf';
        } else if (fileName.includes('.mp4')) {
            return 'doctype:video';
        } else if (fileName.includes('.rtf')) {
            return 'doctype:rtf';
        } else if (fileName.includes('.zip')) {
            return 'doctype:zip';
        } else if (fileName.includes('.txt')) {
            return 'doctype:txt';
        } else if (fileName.includes('.xml')) {
            return 'doctype:xml';
        } else if (fileName.includes('.html') || fileName.includes('.htm')) {
            return 'doctype:html';
        } else if (fileName.includes('.exe')) {
            return 'doctype:exe';
        } else if (fileName.includes('.ai')) {
            return 'doctype:ai';
        } else if (fileName.includes('.psd')) {
            return 'doctype:psd';
        } else if (fileName.includes('.gdoc')) {
            return 'doctype:gdoc';
        } else if (fileName.includes('.gsheet')) {
            return 'doctype:gsheet';
        } else if (fileName.includes('.gform')) {
            return 'doctype:gform';
        } else if (fileName.includes('.gpres')) {
            return 'doctype:gpres';
        } else if (fileName.includes('.slides') || fileName.includes('.keynote')) {
            return 'doctype:slides';
        } else if (fileName.includes('.pack')) {
            return 'doctype:pack';
        } else if (fileName.includes('.audio') || fileName.includes('.mp3')) {
            return 'doctype:audio';
        } else if (fileName.includes('.image') || fileName.includes('.jpg') || fileName.includes('.png')) {
            return 'doctype:image';
        } else if (fileName.includes('.unknown')) {
            return 'doctype:unknown';
        } else {
            return 'doctype:unknown';
        }
    }

    handleFileChange(event){
        console.log('@@@ handleFileChange: ' + event.target.name);
        if(event.target.files.length > 0){
            var fileDataList = [];
            var self = this;

            Array.from(event.target.files).forEach((file, index) => {
                var reader = new FileReader();
                reader.onload = () => {
                    const maxSize = 2 * 1024 * 1024
                    if (file.size <= maxSize) {
                        var base64 = reader.result.split(',')[1];
                        var fileData = {
                            'filename': file.name,
                            'base64': base64,
                        };
                        fileDataList.push(fileData);
                        self.fileDataListFinal.push(fileData);
                        self.uploadDocumentToRecord();
                    }
                };
                reader.readAsDataURL(file);
            });
        }
    }

    async uploadDocumentToRecord(){
        console.log('@@@ uploadDocumentToRecord: ' + this.driveItemId);
        console.log(this.fileDataListFinal);
        this.isSpinner = true;
        try{
            const isSuccess = await uploadDocument({
                recordId: this.recordId,
                driveItemId: this.driveItemId,
                fileDataList: JSON.stringify(this.fileDataListFinal)
            });

            console.log('@@@ isSuccess: ' + isSuccess);
            if(isSuccess){
                if(this.driveItemId){
                    let driveItemList = await getChildrenFromDriveId({driveItemId: this.driveItemId});
                    console.log(driveItemList);
                    
                    let self = this;
                    driveItemList.forEach(function(driveItem){
                        driveItem.iconName = (driveItem.isFolder) ? 'doctype:folder' : self.getIconName(driveItem.name);
                    });

                    console.log('@@@ this.driveItemId: ' + this.driveItemId);
                    this.isSpinner = false;
                    this.currentItems = driveItemList;
                }   
                else{
                    let driveItemList = await getPathDriveItems({recordId: this.recordId});
                    console.log(driveItemList);
        
                    let self = this;
                    let driveItemId;
                    if(driveItemList){
                        driveItemList.forEach(function(driveItem){
                            driveItem.iconName = (driveItem.isFolder) ? 'doctype:folder' : self.getIconName(driveItem.name);
                            driveItemId =  driveItem.currentDriveItemId;
                        });
                    }
                    this.currentItems = driveItemList;
                    this.driveItemId = driveItemId;
                }
        
                const event = new ShowToastEvent({
                    title: 'Success Message',
                    message: 'Successfully Uploaded the File to Sharepoint.',
                    variant: 'success',
                    mode: 'dismissable'
                });
                dispatchEvent(event);
            }
            else{
                const event = new ShowToastEvent({
                    title: 'Error Message',
                    message: 'Unexpected Error occured. Please contact your administrator.',
                    variant: 'error',
                    mode: 'dismissable'
                });
                dispatchEvent(event);
            }

            this.isSpinner = false;
            this.fileDataListFinal = [];
        }catch(error){
            this.isSpinner = false;
            console.error(error);
        }
    }
}