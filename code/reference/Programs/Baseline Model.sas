/*
====================================================================================================================================
SAS PROGRAM : FIT FORECASTING MODELs

MASTERS THESIS - APPLIED ECONOMETRICS

TITLE       : ZONAL AND REGIONAL LOAD FORECASTING IN THE NEW ENGLAND WHOLSEALE ELECTRICITY MARKET
SUBTITLE    : A SEMIPARAMETRIC REGRESSION APPROACH
WRITTEN BY  : JONATHAN T. FARLAND
DATE        : AUGUST 15th, 2013

=====================================================================================================================================
*/


%let dir = C:\Users\jonfar\Documents\Research\Thesis;

/* Libraries */

libname macros "%superq(dir)\SAS\Macros";
libname rawdat "%superq(dir)\Data";
libname sasdat "%superq(dir)\Data\sasdat";
libname output "%superq(dir)\Output";


options symbolgen;
options spool;

%include "&dir\SAS\Macros\load_forecasting_macros.sas" / source2;

/* Specify the load zone as a macro variable. Change this and the code will run with data for the corresponding load zone */

%let lz = region;	

/* Initialize data set */

data original;
	set sasdat.&lz;
run;

/* Use macro to create variable constructs from original data set */

%make_data_set(original, ds);


/*
===============================================================================
Determining Knots for the weather variables
===============================================================================
*/

*The following macro calculated the default number of knots recommended by Ruppert et al (See "Smoothing with Mixed Model Software" with Long Ngo and M.P.Wand);

%default_knots(librefknots=work,data=work.ds,knotdata=knots_temp,varknots=temp);
%default_knots(librefknots=work,data=work.ds,knotdata=knots_hum,varknots=hum);
%default_knots(librefknots=work,data=work.ds,knotdata=knots_cc,varknots=cc);
%default_knots(librefknots=work,data=work.ds,knotdata=knots_ws,varknots=ws);

/*%sendtoexcel3(knots_temp, Model_Analysis, "knots", 2, 6);*/
/*%sendtoexcel3(knots_hum,  Model_Analysis, "knots", 24, 6);*/
/*%sendtoexcel3(knots_cc,   Model_Analysis, "knots", 45, 6);*/
/*%sendtoexcel3(knots_ws,   Model_Analysis, "knots", 48, 6);*/



/* Create a variable to merge by later on. Specifically, 'm' */

data ds2;
	set ds;
	m=1;
run;


data kt_temp;
	set work.knots_temp nobs=nk_temp;
	call symput('nkt_temp',nk_temp);
run;
proc transpose data=work.knots_temp prefix=knots_temp_ out=knotst_temp;
	var knots;
run;

data kt_hum;
	set work.knots_hum nobs=nk_hum;
	call symput('nkt_hum',nk_hum);
run;
proc transpose data=work.knots_hum prefix=knots_hum_ out=knotst_hum;
	var knots;
run;

data kt_cc;
	set work.knots_cc nobs=nk_cc;
	call symput('nkt_cc',nk_cc);
run;
proc transpose data=work.knots_cc prefix=knots_cc_ out=knotst_cc;
	var knots;
run;

data kt_ws;
	set work.knots_ws nobs=nk_ws;
	call symput('nkt_ws',nk_ws);
run;
proc transpose data=work.knots_ws prefix=knots_ws_ out=knotst_ws;
	var knots;
run;

/* Merge all 'knot' data sets together */

data knotst;
	merge knotst_temp knotst_hum knotst_cc knotst_ws;
	m=1;
run;

/*
===============================================================================
Creating the Z matrix
===============================================================================
*/

data ds3;
	merge ds2 knotst;
	by m;

%let nk1=&nkt_temp;
%let nk2=&nkt_hum;
%let nk3=&nkt_cc;
%let nk4=&nkt_ws;

/* create truncated power functions of degree p=1 */
/* Proc TRANSREG could be used here to create almost any other BASIS for the splines */

array Z1a (&nk1) Z1_1-Z1_&nk1;
array knots1a (&nk1) knots_temp_1-knots_temp_&nk1;
	do k=1 to &nk1;
		Z1a(k)=temp-knots1a(k);
		if Z1a(k) < 0 then Z1a(k)=0;
	end;

array Z2a (&nk2) Z2_1-Z2_&nk2;
array knots2a (&nk2) knots_hum_1-knots_hum_&nk2;
	do k=1 to &nk2;
		Z2a(k)=hum-knots2a(k);
		if Z2a(k) < 0 then Z2a(k)=0;
	end;
array Z3a (&nk3) Z3_1-Z3_&nk3;
array knots3a (&nk3) knots_cc_1-knots_cc_&nk3;
	do k=1 to &nk3;
		Z3a(k)=cc-knots3a(k);
		if Z3a(k) < 0 then Z3a(k)=0;
	end;
array Z4a (&nk4) Z4_1-Z4_&nk4;
array knots4a (&nk4) knots_ws_1-knots_ws_&nk4;
	do k=1 to &nk4;
		Z4a(k)=ws-knots4a(k);
		Z4a(k) = Z4a(k);
		if Z4a(k) < 0 then Z4a(k)=0;
	end;

drop knots1_1-knots1_&nk1 knots2_1-knots2_&nk2
			knots3_1-knots3_&nk3 knots4_1-knots4_&nk4 _name_;
run;
/*
===============================================================================
Make Training Dataset
===============================================================================
*/

%let training_beg = '01JAN09 00:00:00'dt;
%let training_end = '31DEC10 23:00:00'dt;

data trn;
	set ds3;
	if datetime ge &training_beg and datetime le &training_end;
	training = 1;
run;

/* Need to create two forecast datasets: (1) without load to make pred with proc mixed and (2) with load to calculate forecasting performance */;

data fcst;
	set ds3;
	if datetime > &training_end;
	drop load; * Need to take out load (dependant variable) during the out of sample period to allow PROC MIXED to make forecasts;
run;

data fcst2;
	set ds3;
	if datetime > &training_end;
run;

/* DS4 ("Data Set 4") is the data set used for fitting the model and allowing PROC MIXED to automatically make forecasts*/

data ds4;
	set trn fcst;
	if training ne 1 then forecast = 1;
	else                  forecast = 0;

/* Create a new 'hour' variable that spans 1 - 24 (as opposed to the way the data came to us, e.g., 0-23) */
	hour2 = hour+1; drop hour;
run;

/*
===============================================================================
Fit the model
===============================================================================
*/

ods listing;
ods html;

proc sort data = ds4;
	by hour2;
run;

ods output CovParms=work.varcomp FitStatistics=work.FitStatistics LRT=work.RatioTest
		   SolutionF=work.FParms SolutionR=work.RParms Tests3=work.FixedTests Type1=work.ANOVA;
ods graphics on;
proc mixed data = ds4 noprofile method=REML plots(maxpoints=50000)=residualpanel;
by hour2; * estimating a different for each model of the day works very very well;
	model load = tuesday--friday month1-month11 nonworking lag24/*lag48*/--lag168 temp hum cc ws /  solution outp=work.yhat;
	random Z1_1-Z1_&nk1 / type=toep(1) s;
	random Z2_1-Z2_&nk2 / type=toep(1) s;
	random Z3_1-Z3_&nk3 / type=toep(1) s;
	random Z4_1-Z4_&nk4 / type=toep(1) s;
run;
ods graphics off;

data parms;
	set Fparms
		Rparms;
	keep effect estimate;
run;

/*%sendtoexcel3(fparms, Model_Analysis, "output", 2, 2);*/
/*%sendtoexcel3(rparms, Model_Analysis, "output", 2, 10);*/


/*
===============================================================================
Calculate MAPE, MAE, MSD
===============================================================================
*/
proc sort data = yhat;
	by datetime;
run;

/* Within-Sample MAPE / MAE / MSD */

data within_sample_mape;
	set yhat(keep= year month datetime load pred resid hour2 forecast);

	if resid = '.' then delete; 
	if resid <0  then resid = resid*-1;
	
	rel_error = resid/load;
	abs_pct_error = rel_error*100;
	abs_squared_error = resid*resid;

	/* Make sure that we limit to the within-sample period */
	if year in ('2009' '2010') then output;

	rename resid = abs_error;

/* Forecasting performance for the entire within-sample period */

proc summary;
	var abs_error abs_pct_error abs_squared_error;
	output out = within_sample_mape2(drop = _FREQ_ _TYPE_)
	   mean(abs_error)=MAE
	   mean(abs_pct_error)=MAPE
       mean(abs_squared_error)=MSD;
run;


/* Forecasting performance for every hour */

proc sort data = within_sample_mape;
	by hour2;
run;
proc summary data = within_sample_mape;
by hour2;
	var abs_error abs_pct_error abs_squared_error;
	output out = within_sample_mape3(drop = _FREQ_ _TYPE_)
	   mean(abs_error)=MAE
       mean(abs_pct_error)=MAPE
       mean(abs_squared_error)=MSD;
run;

/* Forecasting performance for every month */

proc sort data = within_sample_mape;
	by month;
run;
proc summary data = within_sample_mape;
by month;
	var abs_error abs_pct_error abs_squared_error;
	output out = within_sample_mape4(drop = _FREQ_ _TYPE_)
	   mean(abs_error)=MAE
       mean(abs_pct_error)=MAPE
       mean(abs_squared_error)=MSD;
run;

/* Out of Sample MAPE / MAE / MSD */

data out_of_sample_mape;
	merge fcst2(keep=load datetime) yhat(keep= year day month hour2 pred datetime forecast stderrpred  df upper lower);
	by datetime;
		resid = load - pred;
	if resid <0 then resid = resid*-1;
	if forecast = 1;
		rel_error = resid/load;
		abs_pct_error = rel_error*100;
		abs_squared_error = resid*resid;
	rename resid = abs_error;
	/* limit out of sample to just 2011*/
	if year = '2011' then output;
	if datepart(datetime) ge '31DEC11'd then delete;


/* Forecasting performance for the entire out of sample period */

proc summary;
	var abs_error abs_pct_error abs_squared_error;
	output out = out_of_sample_mape2(drop = _FREQ_ _TYPE_)
	    mean(abs_error)=MAE 
		mean(abs_pct_error)=MAPE 
		mean(abs_squared_error)=MSD;
run;


/* Forecasting Performance for every hour */

proc sort data = out_of_sample_mape;
	by hour2;
run;
proc summary data = out_of_sample_mape;
by hour2;
	var abs_error abs_pct_error abs_squared_error;
	output out = out_of_sample_mape3(drop = _FREQ_ _TYPE_)
		mean(abs_error)=MAE
		mean(abs_pct_error)=MAPE
		mean(abs_squared_error)=MSD;
run;


/*
===============================================================================
Within Sample Analysis
===============================================================================
*/

/* Plots of within-sample predictions and actual load */

ods graphics;
data yhat1;
	set yhat;
	if date ge '01JUL10'd and date le '07JUL10'd;
	   log_load = log(load);
	  
proc sgplot;
	scatter x=datetime y=load / markerattrs=(color=black size=5);
	series x=datetime y=pred / markerattrs=(color=red size=5);
	series x = datetime y=Upper ;
	series x = datetime y=Lower ;
    xaxis label = "Date" grid;
	yaxis label = "Load (MW)" grid;
run;
ods graphics off;


ods graphics;
data yhat2;
	set yhat;
	if date ge '01JUL10'd and date le '31JUL10'd;
proc sgplot;
	scatter x=datetime y=load / markerattrs=(color=black size=5);
	series x=datetime y=pred / markerattrs=(color=red size=5);
	/*series x = datetime y=Upper ;
	series x = datetime y=Lower ;*/
    xaxis label = "Date" grid;
	yaxis label = "Load (MW)" grid;
run;
ods graphics off;



/* HISTOGRAM: Residuals */

ods graphics on;
proc sgplot data = yhat;
	histogram resid;
	density resid;
	density resid / type=kernel;
run;
ods graphics off;

ods graphics on;
proc sgplot data = yhat;
	histogram load;
	density load;
	density load / type=kernel;
run;
ods graphics off;

/* HISTOGRAM : LOG LOAD. What is this variables distribution? */

ods graphics on;
proc sgplot data = yhat1;
	histogram log_load;
	density log_load;
	density log_load / type=kernel;
run;
ods graphics off;

/* PLOT : temperature * load/pred relationships */

ods graphics on;
proc sgplot data = yhat;
	scatter x = temp y = load;
	scatter x = temp y = pred;
	scatter x = temp y = Upper;
	scatter x = temp y = Lower;
run; 
ods graphics off;

/* PLOT : cloud cover * load/pred relationships */

ods graphics on;
proc sgplot data = yhat;
	scatter x = cc y = load;
	scatter x = cc y = pred;
run; 
ods graphics off;

/* Error Breakdown */

data err1;
	set within_sample_mape;
		hour2=hour+1;
ods graphics on;
proc sgplot ;
	vbox abs_pct_error / category=hour2;
	yaxis label = "Error Percent" grid;
	xaxis label = "Hour of the Day" grid;
run;
ods graphics off;

/* What are the statistical properties of the errors? */

%macro dist_err;
	proc univariate data = yhat;
		var resid;
		histogtam / normal;
	run;
%mend;



/*
===============================================================================
Out of Sample Analysis
===============================================================================
*/

/* PLOT : cloud cover * load/pred relationships */

ods graphics;
proc sort data = out_of_sample_mape;
	by datetime;
run;

data yhat2;
	set out_of_sample_mape;
	if datetime ge '01JUL11 00:00:00'dt and datetime le '08JUL11 00:00:00'dt;
		log_load = log(load);
proc sgplot ;
	series x=datetime y=load ;
	series x=datetime y=pred ;
    xaxis label = "Date";
	yaxis label = "Load (MW)";
run;
ods graphics off;


data WS_output;
	set yhat;
	if forecast = 0;
	keep year day month hour2 load  pred stderrpred df lower upper resid;
run;

data OS_output;
	set out_of_sample_mape;
   	keep year day month hour2 load  pred stderrpred df lower upper;
run;


/* Output results to an excel document */

proc transpose data = FitStatistics out = FitStatistics2;
  id Descr;
  var value;
  by hour2 ;
run;

proc transpose data = VarComp out = VarComp2;
 /* id CovParm;*/
  var Estimate;
  by hour2 ;
  idlabel covparm;
run;

/* the code below was originally used to output the knots for each model. This was before we were estimating a model for each hour of the day.
proc transpose data = knotst out = knot_out;
run;
data knot_out;
	set knot_out;
	if _NAME_ = "m" then delete;
	keep knots;
run;
*/

/*
===============================================================================
Output
===============================================================================
*/


/* Use a macro to output relevant results to an excel workbook to quickly look at and use in manuscript / presentation */

/* Fit Statistics and Variance Components */
/*%SendToExcel3(FitStatistics2,      ResultsWorkbook,"&lz.Results",34,2);*/
/*%SendToExcel3(VarComp2,            ResultsWorkbook,"&lz.Results",61,2);*/
/**/
/*%SendToExcel3(Within_sample_mape2, ResultsWorkbook,"&lz.Results",2,2);*/
/*%SendToExcel3(out_of_sample_mape2, ResultsWorkbook,"&lz.Results",5,2);*/
/**/
/*%sendtoexcel3(RatioTest,           ResultsWorkbook,"&lz.Results",8,2);*/
/*/* FIXME: need to output fixed effects tests as well */*/
/**/
/*%SendToExcel3(FParms,              ResultsWorkbook,"&lz.Results",114,2);*/
/*%SendToExcel3(RParms,              ResultsWorkbook,"&lz.Results",788,2);*/
/**/
/*%SendToExcel3(Within_sample_mape3, ResultsWorkbook,"&lz.Results",2,36);*/
/*%SendToExcel3(out_of_sample_mape3, ResultsWorkbook,"&lz.Results",2,41);*/
/**/
/*%SendToExcel3(WS_OutPut,           ResultsWorkbook,"&lz.Results",2,12);*/
/*%SendToExcel3(OS_OutPut,           ResultsWorkbook,"&lz.Results",2,24);


%macro export_xls(data);
	proc export
	  data = &data
	  outfile = "C:\Users\jonfar\Documents\Research\Thesis\Results\&lz._model_results.xlsx"
		dbms = excel
	  label replace;
	  sheet = "&data ";
	run;
%mend;

%export_xls(fparms);
%export_xls(rparms);
%export_xls(FitStatistics2);
%export_xls(VarComp2);
%export_xls(Within_sample_mape2);
%export_xls(out_of_sample_mape2);
%export_xls(RatioTest);
%export_xls(Within_sample_mape3);
%export_xls(out_of_sample_mape3);
%export_xls(WS_OutPut);
%export_xls(OS_OutPut);




/* This was used when we weren't running hourly models
%SendToExcel3(Knot_out,ResultsWorkbook,"&lz.Results",65,11);
*/



data output.&lz._OS;
	set OS_Output;
run;

data output.&lz._WS;
	set WS_Output;
run;






