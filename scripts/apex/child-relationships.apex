Set<String> relevantChildRelationships = new Set<String>{
  'seven20__Accounts__r',
  'seven20__Applications__r',
  'seven20__Candidate_Shifts__r',
  'seven20__Compliances__r',
  'seven20__Contacts__r',
  'seven20__Education_History__r',
  'seven20__Employment_History__r',
  'seven20__Interviews__r',
  'seven20__Job_Board_Applications__r',
  'seven20__Job_Leads__r',
  'seven20__Jobs__r',
  'seven20__Placements__r',
  'seven20__References__r',
  'seven20__Relationships__r',
  'Tigris__Interesses__r',
  'Tigris__Opleidingen_en_certificaten__r',
  'Tigris__Talen__r',
  'Tigris__Vaardigheden__r',
  'Tigris__Werkervaringen__r'
};

List<Schema.ChildRelationship> contactChildRelationships = Contact.SObjectType.getDescribe()
  .getChildRelationships();

Id contact_id = '...'; // replace with actual contact id

for (Schema.ChildRelationship cr : contactChildRelationships) {
  String relName = cr.getRelationshipName();
  if (!relevantChildRelationships.contains(relName))
    continue;

  Schema.DescribeSObjectResult childDescription = cr.getChildSObject()
    .getDescribe();
  Set<String> childFields = childDescription.fields.getMap().keySet();

  List<SObject> childRecords = Database.query(
    'SELECT ' +
      String.join(new List<String>(childFields), ',') +
      ' FROM ' +
      childDescription.getName() +
      ' WHERE ' +
      cr.getField().getDescribe().getName() +
      ' = :contact_id'
  );
  System.debug('Child records for relationship: ' + relName);
  List<Map<String, Object>> result = new List<Map<String, Object>>();
  for (SObject rec : childRecords) {
    Map<String, Object> recData = new Map<String, Object>();
    Map<String, Object> recPopulatedFields = rec.getPopulatedFieldsAsMap();
    for (String key : recPopulatedFields.keySet())
      recData.put(key, recPopulatedFields.get(key));

    System.debug(recData);
  }
}
