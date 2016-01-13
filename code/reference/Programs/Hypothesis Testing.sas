%let dir = C:\Users\jonfar\Documents\Research\Thesis;

/* Libraries */

libname macros "%superq(dir)\SAS\Macros";
libname rawdat "%superq(dir)\Data";
libname sasdat "%superq(dir)\Data\sasdat";
libname output "%superq(dir)\Output";


options symbolgen;
options spool;

%include "&dir\SAS\Macros\load_forecasting_macros.sas" / source2;

/* Specify the load zone to forecast for and the training year - used at the end of this program */

%let lz = Region;	

data original;
	set sasdat.&lz;
run;

%make_data_set(original, ds);


/*
===============================================================================
Load Input Data Set
===============================================================================
*/



data trn_2009;
	set ds;
	if datetime ge '01JAN09 00:00:00'dt and datetime le '31DEC09 00:00:00'dt;
		log_load = log(load);
run;

data trn_2010;
	set ds;
	if datetime ge '01JAN10 00:00:00'dt and datetime le '31DEC10 00:00:00'dt;
		log_load = log(load);
run;

data trn_2011;
	set ds;
	if datetime ge '01JAN11 00:00:00'dt and datetime le '31DEC11 00:00:00'dt;
		log_load = log(load);
run;


 /*
===============================================================================
Likelihood Ratio Test for Nonlinearity
===============================================================================
*/
/*within sample */
data ws;
	set ds;
	if datetime ge '01JAN09 00:00:00'dt and datetime le '31DEC10 00:00:00'dt;
run;


ods graphics on;
ods output ANODEV=work.ADEV_ws FitSummary=work.FitSummary_ws ParameterEstimates = work.ParameterEstimates_ws;
proc gam data = ws
	plots = components(CLM ADDITIVE COMMONAXES);
	model load = param(tuesday--friday) param(month1--month11) param(nonworking) param(lag24--lag168)
			     spline(temp)          spline(hum)            spline(cc)        spline(ws)          / method=gcv;		
run;
ods graphics off;
%sendtoexcel3(ADEV_ws, tests, "&lz.Tests", 3, 2); 
%sendtoexcel3(FitSummary_ws, tests, "&lz.Tests", 3, 8); 
%sendtoexcel3(ParameterEstimates_ws, tests, "&lz.Tests", 9, 2); 

/* Out of Sample */

data os;
	set ds;
	if datetime ge '01JAN11 00:00:00'dt and datetime le '31DEC11 00:00:00'dt;
run;

ods graphics on;
ods output ANODEV=work.ADEV_os FitSummary=work.FitSummary_os ParameterEstimates = work.ParameterEstimates_os;
proc gam data = os
	plots = components(CLM ADDITIVE COMMONAXES);
	model load = param(tuesday--friday) param(month1--month11) param(nonworking) param(lag24--lag168)
			     spline(temp)          spline(hum)            spline(cc)        spline(ws)          / method=gcv;		
run;



ods graphics off;
%sendtoexcel3(ADEV_os, tests, "&lz.Tests", 39, 2); 
%sendtoexcel3(FitSummary_os, tests, "&lz.Tests", 39, 8); 
%sendtoexcel3(ParameterEstimates_os, tests, "&lz.Tests", 48, 2); 

/*



ods graphics on;
proc gam data = trn_2009 plots = components(CLM ADDITIVE COMMONAXES);
title "&lz 2009";
	model load = param(monday--friday) param(month1--month11) param(nonworking) param(lag24--lag168)
			     spline(temp)          spline(hum)            spline(cc)        spline(ws)          / method=gcv;
			output out = gam_out all;
run;
title;
ods graphics off;

ods graphics on;
proc gam data = trn_2010 plots = components(CLM ADDITIVE COMMONAXES);
title "&lz 2010";
	model load = param(monday--friday) param(month1--month11) param(nonworking) param(lag24--lag168)
			     spline(temp)          spline(hum)            spline(cc)        spline(ws)          / method=gcv;
			
run;
title;
ods graphics off;

ods graphics on;
proc gam data = trn_2011 plots = components(CLM ADDITIVE COMMONAXES);
title "&lz 2011";
	model load = param(monday--friday) param(month1--month11) param(nonworking) param(lag24--lag168)
			     spline(temp)          spline(hum)            spline(cc)        spline(ws)          / method=gcv;
			
run;
title;
ods graphics off;
*/

/*

 

proc sgplot data = gam_out;
	series x = hum y = p_hum;
	scatter x = hum y = load;
run;

/* what is the distribution of electricity load? 
data log_;
	set ds;
	logload= log(load);
proc univariate;
 histogram load;
 histogram logload;
run;


ods graphics on;
proc reg data = ds;
title "Nonlinear Temperature Model";

model load = month1-month11 nonworking lag24--lag168 temp tempsqr tempcub hum cc ws;
output out = model_5
		   predicted = pload;
run;
ods graphics off;
*/

/*
===============================================================================
Tests for Unit Roots and Cointegration
===============================================================================
*/

/*

proc varmax data=test;
      model load temp / p=2 cointtest dftest;
run;
proc varmax data=ds;
      model load hum / p=2 cointtest dftest;
run;
proc varmax data=ds;
      model load ws / p=2 cointtest dftest;
run;
proc varmax data=ds;
      model load cc / p=2 cointtest dftest;
run;


ods graphics on;
proc reg data = original;
	model load = temp lag1 templag;
	test temp + loadlag + templag = 1;
run;
ods graphics off;


proc varmax data=ds; 
id date interval=hour; 
model load temp hum cc ws/ p=2 lagmax=24 dftest print=(iarr(3)) cointtest=(johansen=(iorder=2)) ecm=(rank=1 normalize=load);
	cointeg rank=1 normalize=load exogeneity; 
run;


data test; set original;
	templag = lag(temp);
	loadlag = lag(load);
run;

proc reg data = test;
model load = temp loadlag templag;
test temp + loadlag + templag = 1;
run;



*/
