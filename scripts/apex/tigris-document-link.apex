Id contentDocumentId = '069P500000cYBWEIA4';
Id contactId = '003P5000010ZxvxIAC';

// Insert a new Tigris__Overeenkomst__c record
Tigris__Overeenkomst__c newRecord = new Tigris__Overeenkomst__c(
  Name = 'Example output',
  Tigris__ContentDocumentId__c = contentDocumentId,
  Tigris__Kandidaat__c = contactId,
  Tigris__Type_document__c = 'CV'
);
insert newRecord;
