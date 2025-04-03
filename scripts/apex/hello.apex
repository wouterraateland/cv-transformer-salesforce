Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe()
  .get('Contact')
  .getDescribe()
  .fields.getMap();

for (String key : fieldMap.keySet())
  System.debug(key);

// for (String key : Schema.getGlobalDescribe().keySet())
//   System.debug(key);
