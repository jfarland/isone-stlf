%let dir = C:\Users\jonfar\Documents\Research\Thesis;

/* Libraries */

libname macros "%superq(dir)\SAS\Macros";
libname rawdat "%superq(dir)\Data";
libname sasdat "%superq(dir)\Data\sasdat";
libname output "%superq(dir)\Output";


options symbolgen;
options spool;

%include "&dir\SAS\Macros\load_forecasting_macros.sas" / source2;
%let lz = region;	
%let trn_year = 2009;

%let forecast_beg = '01JAN10 00:00:00'dt;
%let forecast_end = '31DEC10 23:00:00'dt;

data fcst;
	set ds3;
	if datetime ge &forecast_beg and datetime le &forecast_end;
	m=1;
run;

proc transpose data = parms out = parmst;
run;

proc score data = fcst score = parmst out =oos type = parms;
	var load monday--friday month1-month11 nonworking lag24--lag168 temp hum cc ws Z1_1-Z1_&nk1 Z2_1-Z2_&nk2 Z3_1-Z3_&nk3 Z4_1-Z4_&nk4;
run;




proc score
		data=Fitness 
		score=RegOut 
		out=RScoreP 
		type=parms;

   var Age Weight RunTime RunPulse RestPulse;
run;



/* Use PROC IML to make predicted values */

proc iml;
	use fparms; read all;
	use rparms; read all;
	use fcst2; read all;

	c = one || monday--friday || month1--month11 || nonworking || lag24--lag168|| temp || hum || cc || ws ;

	print c;

	create c var {parameter} ; 
	append from c;

quit;
/*
===============================================================================
Load Inputs
===============================================================================
*/





quit;





/*
===============================================================================
Processing
===============================================================================
*/


/*
===============================================================================
Save Outputs
===============================================================================
*/
