Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe()
  .get('ContentVersion')
  .getDescribe()
  .fields.getMap();

for (String key : fieldMap.keySet())
  System.debug(key);

// for (String key : Schema.getGlobalDescribe().keySet())
//   System.debug(key);
