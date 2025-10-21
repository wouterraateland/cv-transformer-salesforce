Contact contact = [
  SELECT Id
  FROM Contact
  ORDER BY CreatedDate DESC
  LIMIT 1
  OFFSET 1973
];

String contactId = contact.id;

String fieldnameNormalize(String fieldname) {
  if (fieldname.startsWith('seven20__'))
    fieldname = fieldname.substring(9);
  if (fieldname.endsWith('__c'))
    fieldname = fieldname.substring(0, fieldname.length() - 3);
  if (fieldname.endsWith('__r'))
    fieldname = fieldname.substring(0, fieldname.length() - 3);
  return fieldname;
}

Set<String> blacklistedFields = new Set<String>{
  'Accepts_Floats__c',
  'AccountId',
  'Ambition_Record_Type_Banner__c',
  'AmbTech_Candidate__c',
  'Candidate_Cleared__c',
  'CreatedById',
  'CreatedDate',
  'CVTransformer__cvt_id__c',
  'CVTransformer__cvt_secret__c',
  'Dashboard_Access__c',
  'Disable_Hot_Boss__c',
  'DoNotCall',
  'et4ae5__HasOptedOutOfMobile__c',
  'Group_Office__c',
  'HasOptedOutOfEmail',
  'HomePhone',
  'Hot_Boss__c',
  'IsDeleted',
  'IsEmailBounced',
  'IsPriorityRecord',
  'LastModifiedById',
  'LastModifiedDate',
  'LastReferencedDate',
  'LastViewedDate',
  'MobilePhone',
  'Opted_In_SMS_Message__c',
  'Opted_Out_Marketing_Emails__c',
  'OtherPhone',
  'Phone',
  'PhotoUrl',
  'Record_Type_Name',
  'RecordTypeId',
  'seven20__Account__c',
  'seven20__Candidate__c',
  'seven20__Candidate_Source_Detail__c',
  'seven20__Candidate_Status__c',
  'seven20__Created_via_Daxtra__c',
  'seven20__CV_File_Id__c',
  'seven20__CV_File_Name__c',
  'seven20__Full_CV__c',
  'seven20__Is_Indexed_on_Daxtra__c',
  'seven20__Job__c',
  'seven20__Job_ATS__c',
  'seven20__Job_Board_Id__c',
  'seven20__Job_Board_Id__c',
  'seven20__Parser_Status__c',
  'seven20__Record_Type_Name__c',
  'seven20__Sync_Status__c',
  'Status_Icon__c',
  'SystemModstamp',
  'Temp_Traitor__c',
  'Temp_Traitor_Client__c',
  'To_Archive__c',
  'Traitor__c',
  'tubl__TextUs_Indexed_Phone_3__c',
  'tubl__TextUs_Indexed_Phone_5__c',
  'tubl__TextUs_Phone__c'
};

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
  'seven20__Relationships__r'
};

Set<String> blacklistApply(Set<String> fields) {
  Set<String> lowercaseBlacklistedFields = new Set<String>();
  for (String field : blacklistedFields)
    lowercaseBlacklistedFields.add(field.toLowerCase());
  Set<String> result = new Set<String>();
  for (String field : fields)
    if (!lowercaseBlacklistedFields.contains(field.toLowerCase()))
      result.add(field);

  return result;
}

Schema.DescribeSObjectResult contactDescription = Schema.getGlobalDescribe()
  .get('Contact')
  .getDescribe();
Set<String> contactFields = blacklistApply(
  contactDescription.fields.getMap().keySet()
);

List<Schema.ChildRelationship> contactChildRelationships = contactDescription
  .getChildRelationships();

SObject contactObject = Database.query(
  'SELECT ' +
    String.join(new List<String>(contactFields), ',') +
    ' FROM Contact WHERE Id = :contactId'
);
Map<String, Object> contactData = contactObject.getPopulatedFieldsAsMap();

Map<String, Object> data = new Map<String, Object>();
for (String key : contactData.keySet())
  data.put(fieldnameNormalize(key), contactData.get(key));

String phone = (String) contactData.get('MobilePhone');
if (phone == null)
  phone = (String) contactData.get('OtherPhone');
if (phone == null)
  phone = (String) contactData.get('HomePhone');
if (phone == null)
  phone = (String) contactData.get('Phone');
data.put('Phone', phone);

for (Schema.ChildRelationship cr : contactChildRelationships) {
  String relName = cr.getRelationshipName();
  if (!relevantChildRelationships.contains(relName))
    continue;

  Schema.DescribeSObjectResult childDescription = cr.getChildSObject()
    .getDescribe();
  Set<String> childFields = blacklistApply(
    childDescription.fields.getMap().keySet()
  );

  List<SObject> childRecords = Database.query(
    'SELECT ' +
      String.join(new List<String>(childFields), ',') +
      ' FROM ' +
      childDescription.getName() +
      ' WHERE ' +
      cr.getField().getDescribe().getName() +
      ' = :contactId'
  );
  List<Map<String, Object>> result = new List<Map<String, Object>>();
  for (SObject rec : childRecords) {
    Map<String, Object> recData = new Map<String, Object>();
    Map<String, Object> recPopulatedFields = rec.getPopulatedFieldsAsMap();
    for (String key : recPopulatedFields.keySet())
      recData.put(fieldnameNormalize(key), recPopulatedFields.get(key));

    result.add(recData);
  }

  data.put(fieldnameNormalize(relName), result);
}

System.debug(JSON.serializePretty(data));
