import { LightningElement, api, wire } from 'lwc';
import getCompaniesHouseMetadata from '@salesforce/apex/CompaniesHouseController.getCompaniesHouseMetadata';

export default class CompactLayoutOnHover extends LightningElement {
    @api recordId;
    @api contactName;
    @api fieldValues;
    filteredContactValues = [];
    processedData = [];

    connectedCallback() {
        console.log('CompactLayoutOnHover recordId:: ' + this.recordId);
        console.log('CompactLayoutOnHover contactName:: ' + this.contactName);
        console.log('CompactLayoutOnHover fieldValues:: ' + JSON.stringify(this.fieldValues));
    }

    @wire(getCompaniesHouseMetadata)
    wiredCustomMetadata({ error, data }) {
        if (data) {
            this.filterFields(data);
        } else if (error) {
            // Handle error
        }
    }

    
    filterFields(metadata) {
        console.log('CompactLayoutOnHover metadata:: ' + JSON.stringify(metadata));
        let tempFieldValues = Array.isArray(this.fieldValues) ? this.fieldValues : [this.fieldValues];
        console.log('CompactLayoutOnHover tempFieldValues:: ' + JSON.stringify(tempFieldValues));
        this.filteredContactValues = tempFieldValues.map(record => {
            const filteredFields = {};
            metadata.forEach(field => {
                const fieldName = field.FieldAPIName__c;
                if (fieldName in record) {
                    //filteredFields[field.Field_Label__c] = record[fieldName];
                    filteredFields[field.Field_Label__c] = fieldName == 'Birthdate' ? this.formatContactDOB(record[fieldName]) : record[fieldName];
                } else {
                    filteredFields[field.Field_Label__c] = '';
                }
            });
            return { ...filteredFields };
        });
        console.log('CompactLayoutOnHover this.filteredContactValues:: ' + JSON.stringify(this.filteredContactValues));
        this.processedData = this.filteredContactValues.map(contact => {
            return Object.entries(contact).map(([key, value]) => {
                return { label: key, value: value };
            });
        });
        console.log('CompactLayoutOnHover this.filteredContactValues:: ' + JSON.stringify(this.filteredContactValues));
        console.log('CompactLayoutOnHover this.processedData:: ' + JSON.stringify(this.processedData));
    }

    formatContactDOB(birthdate) {
        const dateObj = new Date(birthdate);
        const day = ('0' + dateObj.getDate()).slice(-2);
        const month = ('0' + (dateObj.getMonth() + 1)).slice(-2);
        const year = dateObj.getFullYear();
        return `${day}/${month}/${year}`;
    }

}