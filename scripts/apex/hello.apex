Contact contact = [
  SELECT
    Birthdate,
    Description,
    Email,
    FirstName,
    HomePhone,
    LastName,
    MobilePhone,
    OtherPhone,
    Phone
  FROM Contact
  WHERE Id = '003QH00000KOe5eYAD'
];

Map<String, Object> data = new Map<String, Object>();
data.put('firstName', contact.FirstName);
data.put('lastName', contact.LastName);
if (contact.Email != null)
  data.put('email', contact.Email);
if (contact.OtherPhone != null)
  data.put('phone', contact.OtherPhone);
if (contact.MobilePhone != null)
  data.put('phone', contact.MobilePhone);
if (contact.HomePhone != null)
  data.put('phone', contact.HomePhone);
if (contact.Phone != null)
  data.put('phone', contact.Phone);
if (contact.Birthdate != null)
  data.put('birthDate', contact.Birthdate.format());
if (contact.Description != null)
  data.put('description', contact.Description);

if (true) {
  SObject seven20Object = Database.query(
    'SELECT ' +
      'seven20__Available_From__c,' +
      'seven20__Current_Day_Rate__c,' +
      'seven20__Current_Employment_Type__c,' +
      'seven20__Current_Salary__c,' +
      'seven20__Desired_Day_Rate__c,' +
      'seven20__Desired_Employment_Type__c,' +
      'seven20__Desired_Salary__c,' +
      'seven20__Driving_Licence__c,' +
      'seven20__Highest_Education_Level__c,' +
      'seven20__Job_Description__c,' +
      'seven20__Languages__c,' +
      'seven20__LinkedIn__c,' +
      'seven20__No_of_Years_Experience__c,' +
      'seven20__Notice_Period__c,' +
      'seven20__Open_to_Relocation__c,' +
      'seven20__University__c,' +
      'seven20__Work_Experience_Total_Months__c,' +
      '(' +
      'SELECT ' +
      'seven20__Comments__c,' +
      'seven20__Degree_Name__c,' +
      'seven20__Degree_Subject__c,' +
      'seven20__Degree_Type__c,' +
      'seven20__End_Date__c,' +
      'seven20__Graduation_Date__c,' +
      'seven20__Measure_Value__c,' +
      'seven20__School_Name__c,' +
      'seven20__School_Type__c,' +
      'seven20__Start_Date__c ' +
      'FROM seven20__Education_History__r' +
      '),' +
      '(' +
      'SELECT ' +
      'seven20__Description__c,' +
      'seven20__End_Date__c,' +
      'seven20__Job_Title__c,' +
      'seven20__Start_Date__c ' +
      'FROM seven20__Employment_History__r' +
      ')' +
      'FROM Contact ' +
      'WHERE Id = \'003QH00000KOe5eYAD\''
  );
  Map<String, Object> seven20Data = (Map<String, Object>) JSON.deserializeUntyped(
    JSON.serialize(seven20Object.getPopulatedFieldsAsMap())
  );

  if (seven20Data.get('seven20__Available_From__c') != null)
    data.put('availableFrom', seven20Data.get('seven20__Available_From__c'));
  if (seven20Data.get('seven20__Current_Day_Rate__c') != null)
    data.put('currentDayRate', seven20Data.get('seven20__Current_Day_Rate__c'));
  if (seven20Data.get('seven20__Current_Employment_Type__c') != null)
    data.put(
      'currentEmploymentType',
      seven20Data.get('seven20__Current_Employment_Type__c')
    );
  if (seven20Data.get('seven20__Current_Salary__c') != null)
    data.put('currentSalary', seven20Data.get('seven20__Current_Salary__c'));
  if (seven20Data.get('seven20__Desired_Day_Rate__c') != null)
    data.put('desiredDayRate', seven20Data.get('seven20__Desired_Day_Rate__c'));
  if (seven20Data.get('seven20__Desired_Employment_Type__c') != null)
    data.put(
      'desiredEmploymentType',
      seven20Data.get('seven20__Desired_Employment_Type__c')
    );
  if (seven20Data.get('seven20__Desired_Salary__c') != null)
    data.put('desiredSalary', seven20Data.get('seven20__Desired_Salary__c'));
  if (seven20Data.get('seven20__Driving_Licence__c') != null)
    data.put('drivingLicence', seven20Data.get('seven20__Driving_Licence__c'));
  if (seven20Data.get('seven20__Highest_Education_Level__c') != null)
    data.put(
      'highestEducationLevel',
      seven20Data.get('seven20__Highest_Education_Level__c')
    );
  if (seven20Data.get('seven20__Job_Description__c') != null)
    data.put('jobDescription', seven20Data.get('seven20__Job_Description__c'));
  if (seven20Data.get('seven20__Languages__c') != null)
    data.put('languages', seven20Data.get('seven20__Languages__c'));
  if (seven20Data.get('seven20__LinkedIn__c') != null)
    data.put('linkedin', seven20Data.get('seven20__LinkedIn__c'));
  if (seven20Data.get('seven20__No_of_Years_Experience__c') != null)
    data.put(
      'noOfYearsExperience',
      seven20Data.get('seven20__No_of_Years_Experience__c')
    );
  if (seven20Data.get('seven20__Notice_Period__c') != null)
    data.put('noticePeriod', seven20Data.get('seven20__Notice_Period__c'));
  if (seven20Data.get('seven20__Open_to_Relocation__c') != null)
    data.put(
      'openToRelocation',
      seven20Data.get('seven20__Open_to_Relocation__c')
    );
  if (seven20Data.get('seven20__University__c') != null)
    data.put('university', seven20Data.get('seven20__University__c'));
  if (seven20Data.get('seven20__Work_Experience_Total_Months__c') != null)
    data.put(
      'workExperienceTotalMonths',
      seven20Data.get('seven20__Work_Experience_Total_Months__c')
    );
  if (seven20Data.get('seven20__Education_History__r') != null) {
    List<Map<String, Object>> educationHistory = new List<Map<String, Object>>();
    for (
      Object eduObject : (List<Object>) seven20Data.get(
        'seven20__Education_History__r'
      )
    ) {
      Map<String, Object> edu = (Map<String, Object>) eduObject;
      Map<String, Object> eduMap = new Map<String, Object>();
      if (edu.get('seven20__Comments__c') != null)
        eduMap.put('comments', edu.get('seven20__Comments__c'));
      if (edu.get('seven20__Degree_Name__c') != null)
        eduMap.put('degreeName', edu.get('seven20__Degree_Name__c'));
      if (edu.get('seven20__Degree_Subject__c') != null)
        eduMap.put('degreeSubject', edu.get('seven20__Degree_Subject__c'));
      if (edu.get('seven20__Degree_Type__c') != null)
        eduMap.put('degreeType', edu.get('seven20__Degree_Type__c'));
      if (edu.get('seven20__End_Date__c') != null)
        eduMap.put('endDate', edu.get('seven20__End_Date__c'));
      if (edu.get('seven20__Graduation_Date__c') != null)
        eduMap.put('graduationDate', edu.get('seven20__Graduation_Date__c'));
      if (edu.get('seven20__Measure_Value__c') != null)
        eduMap.put('measureValue', edu.get('seven20__Measure_Value__c'));
      if (edu.get('seven20__School_Name__c') != null)
        eduMap.put('schoolName', edu.get('seven20__School_Name__c'));
      if (edu.get('seven20__School_Type__c') != null)
        eduMap.put('schoolType', edu.get('seven20__School_Type__c'));
      if (edu.get('seven20__Start_Date__c') != null)
        eduMap.put('startDate', edu.get('seven20__Start_Date__c'));
      educationHistory.add(eduMap);
    }
    data.put('educationHistory', educationHistory);
  }
  if (seven20Data.get('seven20__Employment_History__r') != null) {
    List<Map<String, Object>> employmentHistory = new List<Map<String, Object>>();
    for (
      Object empObject : (List<Object>) seven20Data.get(
        'seven20__Employment_History__r'
      )
    ) {
      Map<String, Object> emp = (Map<String, Object>) empObject;
      Map<String, Object> empMap = new Map<String, Object>();
      if (emp.get('seven20__Description__c') != null)
        empMap.put('description', emp.get('seven20__Description__c'));
      if (emp.get('seven20__End_Date__c') != null)
        empMap.put('endDate', emp.get('seven20__End_Date__c'));
      if (emp.get('seven20__Job_Title__c') != null)
        empMap.put('jobTitle', emp.get('seven20__Job_Title__c'));
      if (emp.get('seven20__Start_Date__c') != null)
        empMap.put('startDate', emp.get('seven20__Start_Date__c'));
      employmentHistory.add(empMap);
    }
    data.put('employmentHistory', employmentHistory);
  }
}

System.debug(JSON.serializePretty(data));
