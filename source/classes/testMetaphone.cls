@isTest
private class testMetaphone {
    
    static testMethod void myUnitTest() {
            
        Metaphone m = new Metaphone();
        Metaphone_Translations__c m1 = new Metaphone_Translations__c(Original_String__c='ABCDEF',Metaphone_String__c='ABKTF');
        Metaphone_Translations__c m2 = new Metaphone_Translations__c(Original_String__C='GHIJKL',Metaphone_String__c='');
        insert m1;
        insert m2;
        
        Test.startTest();        
        System.AssertEquals('B',Metaphone.calculate('bbb'));//removal of duplicate letters, and return B
        System.AssertEquals('N',Metaphone.calculate('KN')); //starts with KN       
        System.AssertEquals('AR',Metaphone.calculate('aR')); //starts with vowel
        System.AssertEquals('M',Metaphone.calculate('MB')); //drop B at end after M
        System.AssertEquals('X',Metaphone.calculate('CIA')); //CIA => X
        System.AssertEquals('TX',Metaphone.calculate('TCIA')); //CIA => X
        System.AssertEquals('X',Metaphone.calculate('CH')); //CH =>X
        System.AssertEquals('K',Metaphone.calculate('C')); //C =>K
        System.AssertEquals('S',Metaphone.calculate('CI')); //CI =>S
        System.AssertEquals('S',Metaphone.calculate('CE')); //CE =>S
        System.AssertEquals('S',Metaphone.calculate('CY')); //CY =>S
        System.AssertEquals('SK',Metaphone.calculate('SCH')); //SCH =>SK
        System.AssertEquals('JJ',Metaphone.calculate('DGE')); //DGE =>JJ
        System.AssertEquals('JJ',Metaphone.calculate('DGY')); //DGY =>JJK
        System.AssertEquals('JJ',Metaphone.calculate('DGI')); //DGI =>JJ
        System.AssertEquals('T',Metaphone.calculate('D')); //D =>T
        System.AssertEquals('F',Metaphone.calculate('F')); //F has no transform
        System.AssertEquals('K',Metaphone.calculate('GHA')); //GH Becomes K if at beginning
        System.AssertEquals('NT',Metaphone.calculate('GNED'));//Drop G if part of GNED and at end, D goes to T
        System.AssertEquals('N',Metaphone.calculate('GN'));//Drop G if part of GN and at end
        System.AssertEquals('NT',Metaphone.calculate('NIGHT'));//Drop GH if not followed by vowel
        System.AssertEquals('K',Metaphone.calculate('G'));//G => K otherwise
        System.AssertEquals('S',Metaphone.calculate('SOH'));//Drop H if after vowel but not before vowel
        System.AssertEquals('SH',Metaphone.calculate('SOHO'));//H stays if after vowel and before vowel
        System.AssertEquals('H',Metaphone.calculate('H'));//H => H
        System.AssertEquals('I',Metaphone.calculate('I'));//I at beginning = I
        System.AssertEquals('J',Metaphone.calculate('J'));//J => J
        System.AssertEquals('K',Metaphone.calculate('CK'));//CK => K and K=>K
        System.AssertEquals('K',Metaphone.calculate('K'));//CK => K and K=>K
        System.AssertEquals('L',Metaphone.calculate('L'));//L=>L
        System.AssertEquals('M',Metaphone.calculate('M'));//M=>M
        System.AssertEquals('N',Metaphone.calculate('N'));//N=>N
        System.AssertEquals('F',Metaphone.calculate('PH'));//PH=>F
        System.AssertEquals('P',Metaphone.calculate('P'));//P=>P
        System.AssertEquals('K',Metaphone.calculate('Q'));//Q=>K
        System.AssertEquals('R',Metaphone.calculate('R'));//R=>R
        System.AssertEquals('X',Metaphone.calculate('SH'));//SH=>X
        System.AssertEquals('X',Metaphone.calculate('SIO'));//SIO=>X
        System.AssertEquals('X',Metaphone.calculate('SIA'));//SIA=>X
        System.AssertEquals('S',Metaphone.calculate('S'));//S=>S
        System.AssertEquals('S',Metaphone.calculate('SCI'));//SCI=>S
        System.AssertEquals('X',Metaphone.calculate('TIA'));//TIA=>X
        System.AssertEquals('X',Metaphone.calculate('TIO'));//TIA=>X
        System.AssertEquals('0',Metaphone.calculate('TH'));//TIA=>X
        System.AssertEquals('X',Metaphone.calculate('TCH'));//T gets dropped and CH becomes X
        System.AssertEquals('T',Metaphone.calculate('T'));//T=>T
        System.AssertEquals('F',Metaphone.calculate('V'));//V=>F
        System.AssertEquals('W',Metaphone.calculate('WH'));//WH=>W
        System.AssertEquals('',Metaphone.calculate('W'));//W gets dropped if not followed by vowel
        System.AssertEquals('W',Metaphone.calculate('WA'));//WA=>W
        System.AssertEquals('S',Metaphone.calculate('X'));//X at beginning transforms to S
        System.AssertEquals('SKS',Metaphone.calculate('SAX'));//otherwise X transforms to KS
        System.AssertEquals('',Metaphone.calculate('Y'));//Y gets dropped if not followed by vowel
        System.AssertEquals('YS',Metaphone.calculate('YES'));//otherwise it is a Y
        System.AssertEquals('S',Metaphone.calculate('Z'));//Z=>S
        
                
        //get the matching list for the ABCDF String
        List<String> myList = m.matchingList('ABCDF','Metaphone_Translations__c','Original_String__c','Metaphone_String__c');
        Boolean foundABCDEF = false;
        
        //loop through the results and see if we find ABCDEF
        for(String s : myList){
            if(s.equals('ABCDEF')) foundABCDEF=true;            
        }             
        //assert that ABCDEF ws found
        system.assert(foundABCDEF);
        
        //Since we can't run ALL data at once, we cannot be sure what data gets processed so it is hard to 
        //assert anything here.  but we need to at least run the methods to get code coverage
        m.callCalculateObject('Metaphone_Translations__c','Original_String__c','Metaphone_String__c');        
        m.reset('Metaphone_String__c','Metaphone_Translations__c');
        
        //set the values for the various tabs on the VF page, leave one from each group blank
        m.ProcessObject = 'Metaphone_Translations__c';
        m.ProcessFieldToTranslate = 'Original_String__c';
        m.ProcessStorageField = '';
        m.MatchObject = 'Metaphone_Translations__c';
        m.MatchFieldToReturn = 'Original_String__c';
        m.MatchFieldtoCompare = 'Metaphone_String__c';
        m.MatchValuetoCompare = '';
        m.ResetObject = 'Metaphone_Translations__c';
        m.ResetFieldToClear = '';
        
        //"click" process, match and reset buttons. should get errors
        m.process();
        m.getMatchingList();
        m.reset();
        
        //check that we have three pagemessage errors
        for(ApexPages.Message a : ApexPages.getMessages()){
            System.debug(a.getDetail());
        }
        System.assertEquals(3, ApexPages.getMessages().size());
        
        //set the remainging values
        m.ProcessStorageField = 'Metaphone_String__c';
        m.MatchValuetoCompare = 'ABCDF';
        m.ResetFieldToClear = 'Metaphone_String__c';
        
        //"click" the process button on the vf page
        m.process();
        
        //since we don't know if m1 would have been processed in the first pass, let's make sure it is updated
        m1.Metaphone_String__c='ABKTF';
        update m1;
        
        //"click" the match button on the vf page
        m.getMatchingList();
        
        //convert an empty string
        m.convert();
        //set valueString and convert that
        m.valueString = 'Boston';
        m.convert();
        system.assertEquals('BSTN',m.convertedValue);
        
        //Check that a match for ABCDEF was found
        foundABCDEF = false;
        //loop through the results and see if we find ABCDEF
        for(String s : m.matchList){
            if(s.equals('ABCDEF')) foundABCDEF=true;            
        }             
        //assert that ABCDEF ws found
        system.assert(foundABCDEF); 
        
        //click our reset count buttons and toggle show hide on Metaphone VF page
        m.countProcessed();
        m.countResetProcessed();
        m.toggleShowJobs();
        System.assertEquals(true,m.showJobs);
        m.toggleShowJobs();
        System.assertEquals(false,m.showJobs);
        m.reset();
        Test.stopTest();
    }
    
}