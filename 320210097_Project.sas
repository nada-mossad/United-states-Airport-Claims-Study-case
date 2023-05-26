*Access Data;
libname tsa "/home/u63383870/EPG1V2/data";

options validvarname=v7;
proc import datafile="/home/u63383870/EPG1V2/data/TSAClaims2002_2017.csv"
             dbms=csv
             out=tsa.TsaImport
             replace;
             guessingrows=max;
run;

*Explore Data;
proc print data=tsa.TsaImport (obs=50);
run;

proc contents data=tsa.TsaImport;
run;

proc freq data=tsa.TsaImport;
 tables Claim_Site Disposition Claim_Type / nocum nopercent;
 tables Date_Received Incident_Date / nocum nopercent;
 format Date_Received Incident_Date year4.;
run;

*Prepare Data;
proc sort data=tsa.TsaImport 
          out=tsa.TsaImport_nodup
          nodupkey;
          by _all_;
run;

proc sort data=tsa.TsaImport_nodup
          out=tsa.TsaImport_sorted;
          by  Incident_Date;
run;

data  tsa.claims_cleaned;
      set tsa.TsaImport_sorted;
      if Claim_Site in ('-',"") then Claim_Site="Unknown";
      if Disposition in ("-","") then Disposition='Unknown';
      if Claim_Type in ("-","") then Claim_Type="Unknown";
      State=upcase(state);
      StateName=propcase(StateName);
      if Incident_Date ="" or Date_Received ="" 
         or  year(Incident_Date) <2002 or  year(Incident_Date) >2017
         or  year(Date_Received) <2002 or  year(Date_Received) >2017
         or Incident_Date > Date_Received 
        then  Date_Issues = "Needs Review";
        drop County City;
        format  Currency dollar10.2 Date_Received  Incident_Date date9. ;
        label   Claim_Number="Claim Number"
                Date_Received="Date Received"
                Incident_Date="	Incident Date"
                Airport_Code="Airport Code"
                Airport_Name="Airport Name"
                Claim_Type="Claim Type"
                Claim_Site="Claim Site"
                Item_Category="Item Category"
                Close_Amount="Close Amount";
run;

*Analyze and Exporte Data;
ods pdf file="/home/u63383870/EPG1V2/data/320210097.pdf"  STYLE=JOURNAL ; 
ods graphics on;
ods noproctitle;
title1 "320210097 report results";
title2 " numbers of date issues are in the data";
proc freq data=tsa.claims_cleaned;
          table Date_Issues / nocum nopercent;          
run;
title; 
title3 " numbers of claims per year of Incident_Date";
proc freq data=tsa.claims_cleaned;
          format Incident_Date year4.;
          table Incident_Date/ nocum nopercent plots=freqplot;
          where Date_Issues ~="Needs Review";
          
run;
title; 
title4 "frequency values for Claim_Type Claim_Site and Disposition for the selected state";
%let  state =NV;
proc freq data=tsa.claims_cleaned; 
          tables Claim_Type  Claim_Site Disposition / nocum nopercent; 
          where state="&state" and Date_Issues ~="Needs Review";
run;
title;
title5 "mean, minimum, maximum, and sum of Close_Amount for the selected state";
proc means data=tsa.claims_cleaned mean min max sum maxdec=0;
     var Close_Amount;
     where state="&state" and Date_Issues ~="Needs Review";  
run;
title;
ods pdf close;
              


