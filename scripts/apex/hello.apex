Set<String> fields = Schema.getGlobalDescribe()
  .get('Contact')
  .getDescribe()
  .fields.getMap()
  .keySet();

for (String fieldName : fields)
  System.debug(fieldName);

// ID contact_id = '003e20000057f8UAAQ';
ID contact_id = '003e2000004CQ7hAAG';

List<SObject> rels = Database.query(
  'SELECT' +
    '	seven20__Document__r.seven20__External_Id__c, seven20__Document__r.seven20__Type__c' +
    ' FROM seven20__Document_Relationship__c WHERE seven20__Contact__c = \'' +
    contact_id +
    '\''
);

for (SObject rel : rels) {
  SObject doc = rel.getSObject('seven20__Document__r');
  System.debug(
    'External Id: ' +
      doc.get('seven20__External_Id__c') +
      ', Type: ' +
      doc.get('seven20__Type__c')
  );
}
