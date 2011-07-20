public with sharing class Metaphone{

    //=========These are our strings and other values for capturing input on the VF Tools Page==========//
    public String ProcessObject {get;set;}
    public String ProcessFieldToTranslate {get;set;}
    public String ProcessStorageField {get;set;}
    public String MatchObject {get;set;}
    public String MatchFieldToReturn {get;set;}
    public String MatchFieldtoCompare {get;set;}
    public String MatchValuetoCompare {get;set;}
    public String ResetObject {get;set;}
    public String ResetFieldToClear  {get;set;}
    public String valueString  {get;set;}
    public String convertedValue {get; private set;}
    public Integer unprocessedCount {get; private set;}
    public Integer processedCount {get; private set;}
    public Boolean showJobs {get;set;}
    public List<String> matchList {get;set;} //This is the list of matching strings for display on the VF Page
        
    //==========Just a simple Constructor to ensure that all of our fields are initialzed to null====//
    public Metaphone(){
        ProcessObject='';
        ProcessFieldToTranslate='';
        ProcessStorageField='';
        MatchObject='';
        MatchFieldToReturn='';
        MatchFieldtoCompare='';
        MatchValuetoCompare='';
        ResetObject='';
        ResetFieldToClear='';
        valueString='';
        unprocessedCount = 0;
        processedCount = 0;
        showJobs = false;        
        matchList = new List<String>();
    }

    //toggle the showJobs value
    public void toggleShowJobs(){
        showJobs = !showJobs;       
    }
    
    //convert a value
    public void convert(){
        if(valueString<>''){
            convertedValue = calculate(valueString);
        }else{
            convertedValue = null;
        }
    }    
    //=====callable method exposed to VF Page.  Checks that all fields are filled in and then calls reset function====//
    public void reset(){
        //are both fields filed in?
        if(ResetFieldToClear.length() > 0 && ResetObject.length() > 0){
            resetAll(ResetFieldToClear,ResetObject); //call the @future reset function            
        }else{
            //if all fields aren't set, send an error back. 
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.FATAL, 'You must fill out both the Object and Field to Store Translations fields.'));
        }                     
    }
    
    //=====callable method exposed to end user.  Checks that all fields are filled in and then calls reset function====//
    public void reset(String theFieldToClear, String theResetObject){
        resetAll(theFieldToClear,theResetObject);
    }    
    
    //=====the actal methed that does the work to reset.  Due to govenor limits we are restricted to 10000 DML Statements====//
    @future static void resetAll(String mpField, String objAPI){
        //build query string and get data
        String qString = 'SELECT id, ' + mpField + ' FROM ' + objAPI + ' WHERE ' + mpfield + ' <> null';
        List<sObject> theList = database.query(qString);
        
        //List to hold items we will be updating (max will be 10000)
        List<sObject> updateList = new List<sObject>();
        
        //counter to keep track of the number of items we are processing
        Integer counter=0;
        
        //loop through the returned data and null out the metaphone field
        for(sObject s : theList){
                s.put(mpField,'');
                updateList.add(s);
                counter++;      
                if(Test.isRunningTest()){
                    if(counter == 500){ //make sure we don't go over 500, if we are running a test
                        update updateList;
                        break; //break out of this since we can't update any more
                    }  
                }else{
                    if(counter == 10000){ //make sure we don't go over 10000, otherwise we will hit govenor limit
                            update updateList;
                            break; //break out of this since we can't update any more
                    }
                }               
        } 
        update updateList; //update the list in case we didn't reacy 10000         
    }
    
    //=======callable methed exposed to VF Page.  Calling this method will process the appropiate data===//      
    public void process(){
        //are all 3 fields filled in
        if(ProcessObject.length() > 0 && ProcessFieldToTranslate.length() > 0 && ProcessStorageField.length() > 0){
            calculateObjectData(ProcessObject, ProcessFieldToTranslate, ProcessStorageField);            
        }else{
            //if not, send back an error
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.FATAL, 'Plese be sure to fill out all 3 text fields'));
       }               
    }
    
    //=======callable methed exposed to end user.  Calling this method will process the appropiate data===//
    public void callCalculateObject(String objName, String fieldName, String metaphoneField){
        calculateObjectData(objName, fieldName, metaphoneField);
    }
    
    //======our @future method to loop through as many records as we can and process them======//
    //======due to govenor limits we may not be able to process everything. Expect around======//
    //======900-1200 records to be processed in a run =========================================//
    @future static void calculateObjectData(String objName, String fieldName, String metaphoneField){
        //Create a query string
        String qString = 'SELECT id, ' + fieldName + ', ' + metaphoneField + ' FROM ' + objName + ' WHERE ' + fieldName + ' <> null' + ' AND ' + metaphoneField + '=null';
        
        //list to hold the items to update
        List<sObject> updateList = new List<sObject>();             
        
        //loop through as many objects as we can and process them through the metaphone algorithm
        for(sObject obj : database.query(qString)){             
                if(Limits.getLimitScriptStatements() - Limits.getScriptStatements() < 1000){
                        //let's call it quits here before we hit the limit;
                        break;
                }
                //add the updated value to the metaphone field on the object
                obj.put(metaphoneField, calculate((String)obj.get(fieldName)));
                //add the object to the list
                updateList.add(obj);                                    
        }
        
        //update the items in the list. 
        update updateList;
        
    }      
    
    //====callable method from VF Page to return list of strings on objects that match the criteria passed in ====//
    public void getMatchingList(){
        //Check that all 4 fields are populated
        if(MatchObject.length() > 0 && MatchFieldToReturn.length() > 0 && MatchValuetoCompare.length() > 0 && MatchFieldtoCompare.length() > 0){
            matchList = matchingList(MatchValuetoCompare,MatchObject,MatchFieldToReturn, MatchFieldtoCompare);
        }else{
            //if not all filled in, send back an error
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.FATAL, 'Plese be sure to fill out all 4 text fields'));
        }               
    }
    
    //=====callable method to get list of matching strings for the input parameters 
    public List<String> matchingList(String inputString, String objName, String fieldName, String metaphoneField){
        //Create a query string
        String qString = 'SELECT id, ' + fieldName + ', ' + metaphoneField + ' FROM ' + objName
                + ' WHERE ' + metaphoneField + '=\'' + calculate(inputString) + '\'';
                
        //get the object that match the criteria
        List<sObject> matchingList = database.query(qString);
        List<String> strList = new List<String>();
        
        //loop though the list of records and create a list of strings to be returned
        for(sObject s : matchingList){
                strList.add((String)s.get(fieldName));
        }
        return strList;         
    }

    //Called from process tab on vf page... sets the counts for the specified object/field populated
    public void countProcessed(){
        if(ProcessObject.length() > 0 && ProcessStorageField.length() > 0){
            String processedQuery = 'Select count() FROM ' + ProcessObject + ' WHERE ' + ProcessStorageField + '<>null';
            processedCount = Database.countQuery(processedQuery);
            String unprocessedQuery = 'Select count() FROM ' + ProcessObject + ' WHERE ' + ProcessStorageField + '=null';
            unprocessedCount = Database.countQuery(unprocessedQuery);
        }
    }
    
    //Called from reset tab on vf page... sets the counts for the specified object/field populated
    public void countResetProcessed(){
        if(ResetObject.length() > 0 && ResetFieldToClear.length() > 0){
            String processedQuery = 'Select count() FROM ' + ResetObject + ' WHERE ' + ResetFieldToClear + '<>null';
            processedCount = Database.countQuery(processedQuery);
            String unprocessedQuery = 'Select count() FROM ' + ResetObject + ' WHERE ' + ResetFieldToClear + '=null';
            unprocessedCount = Database.countQuery(unprocessedQuery);
        }
    }
    

    //===================================================================// 
    //===================================================================// 
    //calculate method to run metaphone algorithm against inputted string// 
    //===================================================================//
    //===================================================================//
         
    public static String calculate(String compareString){
        //Start with a string that is all uppercase
        String startStr = compareString.toUpperCase();

        String cs = '';  //this will be our "compare string"
        String result = ''; //this is our result which we will return at the end of this method      
        
        //check each letter in the string to see if the next letter is the same, if so, drop it, unless it is C
        for(Integer i=0;i<startStr.length()-1;i++){
            if(!startStr.substring(i,i+1).equals(startStr.substring(i+1,i+2)) || startStr.substring(i,i+1).equals('C')){
                cs += startStr.substring(i,i+1);   
            }
        }
        //Add the last letter of the string to the cs string since we didn't get to it in the loop above
        cs += startStr.substring(startStr.length()-1, startStr.length());
        
        //If the word begins with 'KN', 'GN', 'PN', 'AE', 'WR', drop the first letter.
        if( cs.startsWith('KN') ||
            cs.startsWith('GN') ||    
            cs.startsWith('PN') ||
            cs.startsWith('AE') ||
            cs.startsWith('WR')
          ){        
            cs = cs.substring(1,cs.length());
        }
        
        //Create a set containing the 5 vowels.  This will be used multiple times while checking for patterns
        Set<String> VOWELS = new Set<String>();
        VOWELS.add('A');
        VOWELS.add('E');
        VOWELS.add('I');
        VOWELS.add('O');
        VOWELS.add('U');
               
        if(cs.endsWith('MB')){
                cs = cs.substring(0,cs.length()-1);
        }
        
        //Create integer to hold length of the compare string.  cleans up the code a little. 
        Integer cslen = cs.length();
        
        //loop through the string and check each letter, matching against the metaphone patters.
        for(Integer i=0;i<cslen;i++){
            
                //If string starts with vowel, keep it, otherwise drop it.
                if(i==0){
                    for(String s : VOWELS){
                        if(cs.substring(0,1).equals(s)){ result += s; }                    
                    }
                }
            
            if(cs.substring(i,i+1).equals('B')){
                result += 'B';
                continue;
            }      
        
                //'C' transforms to 'X' if followed by 'IA' or 'H' (unless in latter case, it is part of '-SCH-', in which case it transforms to 'K').
                //'C' transforms to 'S' if followed by 'I', 'E', or 'Y'. Otherwise, 'C' transforms to 'K'.
                //CH transforms to K if at the beginning
                if(cs.substring(i,i+1).equals('C')){
                    if(i < cslen-2 && cs.substring(i+1,i+3).equals('IA')){
                        result += 'X';
                    }else if(i < cslen-1 && cs.substring(i+1,i+2).equals('H')){                      
                        if(i>0 && cs.substring(i-1,i).equals('S')){
                            result += 'K';
                            i++;                           
                        }else{
                            result += 'X';
                            i++;                            
                        }
                        }else if(i<cslen-1 && 
                             (cs.substring(i+1,i+2).equals('I') ||
                              cs.substring(i+1,i+2).equals('E') ||
                              cs.substring(i+1,i+2).equals('Y'))
                           ){
                                      
                        if(i>0 && cs.substring(i-1,i).equals('S')){
                                //do nothing and drop C, it is slient
                        }else{
                                result += 'S';
                        }                                                       
                    }else{
                        result += 'K';
                    }
                    continue;
                }
        
               //'D' transforms to 'J' if followed by 'GE', 'GY', or 'GI'. Otherwise, 'D' transforms to 'T'.
               if(cs.substring(i,i+1).equals('D')){
                    if(i<cslen-2 &&
                        (
                            cs.substring(i+1,i+3).equals('GE') ||
                            cs.substring(i+1,i+3).equals('GY') ||
                            cs.substring(i+1,i+3).equals('GI')           
                        )){                        
                        result += 'J';                  
                    }else{
                        result += 'T';
                    }
                    continue;
                }
                
                if(cs.substring(i,i+1).equals('F')){
                    result += 'F';
                    continue;
                }
        
                //Drop 'G' if followed by 'H' and 'H' is not at the end or before a vowel.            
                //Drop 'G' if followed by 'N' or 'NED' and is at the end.
                //'G' transforms to 'J' if before 'I', 'E', or 'Y', and it is not in 'GG'. Otherwise, 'G' transforms to 'K'. Reduce 'GG' to 'G'.                    
                if(cs.substring(i,i+1).equals('G')){
                    if((i==cslen-2 && cs.substring(i,i+2).equals('GN')) || (i==cslen-4 && cs.substring(i,i+4).equals('GNED'))){
                        //do nothing (ie drop G) since G is followed by N or NED and is at the end                      
                    }else if(i==0 && cslen >2 && cs.substring(1,2).equals('H') && VOWELS.contains(cs.substring(2,3))){
                        result += 'K'; //GH at the beginning should result in 'K'
                        i++;           //we know H is next and is taken care of, so skip it
                    }else if((i<cslen-2 && cs.substring(i+1,i+2).equals('H') && !VOWELS.contains(cs.substring(i+2,i+3))) || 
                                        (i<cslen-1 && cs.substring(i+1,i+2).equals('H'))){
                        //do nothing (ie drop G and H) since H is not followed by a vowel
                        i++;
                    }else if(i<cslen-1 && 
                              (cs.substring(i+1,i+2).equals('I')||
                               cs.substring(i+1,i+2).equals('E') ||
                               cs.substring(i+1,i+2).equals('Y')
                              )
                            ){
                        result += 'J';
                        if(cs.substring(i+1,i+2).equals('Y')){ //then y is considered a vowel here
                                i++;
                        }
                    }else{
                        result += 'K';
                        //if(i<cslen-2 && cs.substring(i+1,i+2).equals('H')){ // H is not at end and is silent here
                        //      i++;
                        //      continue;
                        //}
                    }
                    continue;                
                }
        
                //Drop 'H' if after vowel and not before a vowel.
                if(cs.substring(i,i+1).equals('H')){                            
                    if(i>0 && VOWELS.contains(cs.substring(i-1,i))){
                        //we have a vowel before H                    
                        if((i<cslen-1 && !VOWELS.contains(cs.substring(i+1,i+2))) || i==cslen-1){
                            //do nothing since a vowel is after H as well
                        }else{
                            result += 'H'; //H is at the end or not followed by a vowel
                        }    
                    }else{
                        result += 'H';
                    }
                    continue;
                }
                
                if(cs.substring(i,i+1).equals('J')){
                    result += 'J';
                    continue;
                }
                
                //'CK' transforms to 'K'.
                if(cs.substring(i,i+1).equals('K')){
                    if(i>0 && cs.substring(i-1,i).equals('C')){
                        //do nothing since the K is silent (the C was already transformed to K earlier
                    }else{
                        result +='K';
                    } 
                    continue;
                }
                
                if(cs.substring(i,i+1).equals('L')){
                    result += 'L';
                    continue;
                }
                
                if(cs.substring(i,i+1).equals('M')){
                    result += 'M';
                    continue;
                }
                
                if(cs.substring(i,i+1).equals('N')){
                    result += 'N';
                    continue;
                }
        
                //'PH' transforms to 'F'. (the H will get dropped later)
                if(cs.substring(i,i+1).equals('P')){
                    if(i<cslen-1 && cs.substring(i+1,i+2).equals('H')){
                        result += 'F';
                        i++;                    
                     }else{
                        result += 'P';
                    }
                    continue;
                }
                
        
                //'Q' transforms to 'K'.
                if(cs.substring(i,i+1).equals('Q')){
                    result += 'K';
                    continue;
                }
                
                if(cs.substring(i,i+1).equals('R')){
                    result += 'R';
                    continue;
                }
        
                //'S' transforms to 'X' if followed by 'H', 'IO', or 'IA'.
                if(cs.substring(i,i+1).equals('S')){
                    if( (i<cslen-1 && cs.substring(i+1,i+2).equals('H')) ||
                        (i<cslen-2 && (cs.substring(i+1,i+3).equals('IO') || cs.substring(i+1,i+3).equals('IA') ))
                      ){
                        result += 'X';
                        if(cs.substring(i+1,i+2).equals('H')){
                                i++;
                        }              
                    }else{
                        result += 'S';                  
                    }
                    continue;
                }
        
                //'T' transforms to 'X' if followed by 'IA' or 'IO'. 'TH' transforms to '0'. Drop 'T' if followed by 'CH'.
                if(cs.substring(i,i+1).equals('T')){
                    if(i<cslen-2 && (cs.substring(i+1,i+3).equals('IO') || cs.substring(i+1,i+3).equals('IA'))){
                        result += 'X';
                    }else if(i<cslen-1 && cs.substring(i+1,i+2).equals('H')){
                        result += '0'; //this is a zero, representing 'theta'
                        i++; //TH just became 0 so drop the H is no needed.
                    }else if(i<cslen-2 && cs.substring(i+1,i+3).equals('CH')){
                        //do nothing since T is followed by CH and thus gets dropped
                    }else{
                        result += 'T';
                    }
                    continue;
                } 
        
                //'V' transforms to 'F'.       
                if(cs.substring(i,i+1).equals('V')){
                    result += 'F';
                    continue;
                }
        
                //'WH' transforms to 'W' if at the beginning (done earlier). Drop 'W' if not followed by a vowel.
                if(cs.substring(i,i+1).equals('W')){
                    if(i==0 && cslen>1 && cs.substring(i+1,i+2).equals('H')){
                        result+='W';
                        i++;
                    }else if(i<cslen-1 && VOWELS.contains(cs.substring(i+1,i+2))){
                        result += 'W';                    
                    } 
                    continue;               
                }
        
                //'X' transforms to 'S' if at the beginning. Otherwise, 'X' transforms to 'KS'.
                if(cs.substring(i,i+1).equals('X')){
                    if(i==0){
                        result += 'S';
                    }else{
                        result += 'KS';
                    }
                    continue;
                }
                
                //Drop 'Y' if not followed by a vowel.
                if(cs.substring(i,i+1).equals('Y')){
                    if(i<cslen-1 && VOWELS.contains(cs.substring(i+1,i+2))){
                        result += 'Y';                    
                    }
                    continue;                       
                }
        
                //'Z' transforms to 'S'.                
                if(cs.substring(i,i+1).equals('Z')){
                    result += 'S';
                    continue;
                }
                        
        }//end for loop
        return result;
    }
}