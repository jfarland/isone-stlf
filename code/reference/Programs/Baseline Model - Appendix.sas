/*
====================================================================================================================================
SAS PROGRAM : FIT FORECASTING MODELS

MASTERS THESIS - APPLIED ECONOMETRICS

TITLE       : ZONAL AND REGIONAL LOAD FORECASTING IN THE NEW ENGLAND WHOLSEALE ELECTRICITY MARKET
SUBTITLE    : A SEMIPARAMETRIC REGRESSION APPROACH
WRITTEN BY  : JONATHAN T. FARLAND
DATE        : AUGUST 15th, 2013

=====================================================================================================================================
*/

/*clear log and output windows*/
dm "log;    clear";
dm "lst;    clear";
dm "output; clear";

/*directory*/
%let dir = C:\Users\jonfar\Documents\Research\Thesis;

/*libraries*/
libname macros "%superq(dir)\SAS\Macros";
libname rawdat "%superq(dir)\Data";
libname sasdat "%superq(dir)\Data\sasdat";
libname output "%superq(dir)\Output";


options symbolgen;
options spool;

/*seperate program containing macros used below*/
%include "&dir\SAS\Macros\load_forecasting_macros.sas" / source2;

/*specify the load zone as a macro variable*/
%let lz = me;

/*
LOAD ZONE                     VALUE
Entire Region               = region
North Eastern Massachusetts = nemass
South Eastern Massachusetts = semass
Western Massachusetts       = wcmass
Connecticut                 = ct
Rhode Island                = ri
Vermont                     = vt
New Hampshire               = nh
Maine                       = me
*/
/* Log and Output files */
%let log_path = &dir\Results\logs\&lz;


/*clear directory*/
proc datasets lib=work 
	nolist kill; 
quit; run;


/*initialize data set*/
data original;
	set sasdat.&lz;
run;

/*use a subroutine to make necessary variables for model fitting*/
%make_data_set(original, ds);

/*
===============================================================================
Determining Knots for the weather variables
===============================================================================
*/

/*the macro "default_knots" calculates the default number of knots recommended by Ruppert et al (See "Smoothing with Mixed Model Software" with Long Ngo and M.P.Wand)*/
%default_knots(librefknots=work,data=work.ds,knotdata=knots_temp,varknots=temp);
%default_knots(librefknots=work,data=work.ds,knotdata=knots_hum,varknots=hum);
%default_knots(librefknots=work,data=work.ds,knotdata=knots_cc,varknots=cc);
%default_knots(librefknots=work,data=work.ds,knotdata=knots_ws,varknots=ws);


/*create a generic constant to merge later on. specifically, 'm'*/
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

/*merge all 'knot' data sets together */
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

/*create truncated power functions of degree p=1 */

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

/*select training period*/
%let training_beg = '01JAN09 00:00:00'dt;
%let training_end = '31DEC10 23:00:00'dt;

/*isolate training data set*/
data trn;
	set ds3;
	if datetime ge &training_beg and datetime le &training_end;
	training = 1;
run;

/*create two forecast data sets:
	(1) without load to make predictions with proc mixed and
	(2) with    load to calculate forecasting errors from predictions
*/

data fcst;
	set ds3;
	if datetime > &training_end;
	drop load; /*without dependant variable*/
run;

data fcst2;
	set ds3;
	if datetime > &training_end;
run;

/*stack training and forecasted*/

data ds4;
	set trn fcst;
	/*generate forecasting flag*/
	if training ne 1 then forecast = 1;
	else                  forecast = 0;

	/*generate correct hour variable that ranges from 1 - 24 (as opposed to the way the data came to us, e.g., 0-23)*/
	hour2 = hour+1;
	drop hour;
run;

/*
===============================================================================
Fit hourly models
===============================================================================
*/

ods listing;
ods html;

proc sort
	data = ds4;
	by hour2;
run;

ods output CovParms=work.varcomp FitStatistics=work.FitStatistics LRT=work.RatioTest
		   SolutionF=work.FParms SolutionR=work.RParms Tests3=work.FixedTests Type1=work.ANOVA;
ods graphics on;
proc mixed data = ds4 noprofile method=REML plots(maxpoints=50000)=residualpanel;
by hour2; /*estimate hourly models*/
	model load = tuesday--friday month1-month11 nonworking lag24--lag168 temp hum cc ws /  solution outp=work.yhat;
	random Z1_1-Z1_&nk1 / type=toep(1) s;
	random Z2_1-Z2_&nk2 / type=toep(1) s;
	random Z3_1-Z3_&nk3 / type=toep(1) s;
	random Z4_1-Z4_&nk4 / type=toep(1) s;
run;
ods graphics off;

/*stack fixed and random solutions*/
data parms;
	set Fparms
		Rparms;
	keep effect estimate;
run;

/*
===============================================================================
Calculate MAPE, MAE, MSD
===============================================================================
*/
proc sort data = yhat;
	by datetime;
run;

/*WITHIN SAMPLE FORECASTING PERFORMANCE*/

data within_sample_mape;
	set yhat(keep= year month datetime load pred resid hour2 forecast);

	if resid = '.' then delete; 
	if resid <0    then resid = resid*-1;
	
	rel_error         = resid/load;
	abs_pct_error     = rel_error*100;
	abs_squared_error = resid*resid;

	/*make sure we limit to just the within sample time frame*/
	if year in ('2009' '2010') then output;

	rename resid = abs_error;

/*calculate total MAE, MAPE, and MSD*/
proc summary;
	var abs_error abs_pct_error abs_squared_error;
	output out = within_sample_mape2(drop = _FREQ_ _TYPE_)
	   mean(abs_error)        = MAE
	   mean(abs_pct_error)    = MAPE
       mean(abs_squared_error)= MSD;
run;


/*calculate hourly MAE, MAPE, and MSD*/
proc sort data = within_sample_mape;
	by hour2;
run;

proc summary data = within_sample_mape;
	by hour2;
	var abs_error abs_pct_error abs_squared_error;
	output out = within_sample_mape3(drop = _FREQ_ _TYPE_)
	   mean(abs_error)        = MAE
       mean(abs_pct_error)    = MAPE
       mean(abs_squared_error)= MSD;
run;

/*calculate monthly MAE, MAPE, and MSD*/
proc sort data = within_sample_mape;
	by month;
run;

proc summary data = within_sample_mape;
	by month;
	var abs_error abs_pct_error abs_squared_error;
	output out = within_sample_mape4(drop = _FREQ_ _TYPE_)
	   mean(abs_error)        = MAE
       mean(abs_pct_error)    = MAPE
       mean(abs_squared_error)= MSD;
run;

/*OUT OF SAMPLE FORECASTING PERFORMANCE*/

data out_of_sample_mape;
	merge fcst2(keep=load datetime) yhat(keep= year day month hour2 pred datetime forecast stderrpred  df upper lower);
	by datetime;
		resid = load - pred;
	if resid <0 then resid = resid*-1;
	if forecast = 1;
		rel_error         = resid/load;
		abs_pct_error     = rel_error*100;
		abs_squared_error = resid*resid;
	rename resid = abs_error;
	/*limit out of sample to just 2011*/
	if year = '2011' then output;
	if datepart(datetime) ge '31DEC11'd then delete;

/*calculate total MAE, MAPE, and MSD*/
proc summary;
	var abs_error abs_pct_error abs_squared_error;
	output out = out_of_sample_mape2(drop = _FREQ_ _TYPE_)
	    mean(abs_error)        = MAE 
		mean(abs_pct_error)    = MAPE 
		mean(abs_squared_error)= MSD;
run;


/*calculate hourly MAE, MAPE, and MSD*/
proc sort data = out_of_sample_mape;
	by hour2;
run;

proc summary data = out_of_sample_mape;
	by hour2;
	var abs_error abs_pct_error abs_squared_error;
	output out = out_of_sample_mape3(drop = _FREQ_ _TYPE_)
		mean(abs_error)       = MAE
		mean(abs_pct_error)   = MAPE
		mean(abs_squared_error)=MSD;
run;

/*calculate monthly MAE, MAPE, and MSD*/
proc sort data = out_of_sample_mape;
	by month;
run;

proc summary data = out_of_sample_mape;
	by month;
	var abs_error abs_pct_error abs_squared_error;
	output out = out_of_sample_mape4(drop = _FREQ_ _TYPE_)
	   mean(abs_error)        = MAE
       mean(abs_pct_error)    = MAPE
       mean(abs_squared_error)= MSD;
run;

/*
===============================================================================
prepare output
===============================================================================
*/

/*initialize output data sets*/
data WS_output;
	set yhat;
	if forecast = 0;
	keep year day month hour2 load  pred stderrpred df lower upper resid;
run;

data OS_output;
	set out_of_sample_mape;
   	keep year day month hour2 load  pred stderrpred df lower upper;
run;


/*transpose hourly results for outputting*/
proc transpose
	data = FitStatistics
	out  = FitStatistics2;
    id  Descr ;
    var value ;
    by  hour2 ;
run;

proc transpose
	data = VarComp
	out = VarComp2;
/*    id CovParm;*/
	  var     Estimate;
	  by      hour2   ;
	  idlabel covparm ;
run;


/*
===============================================================================
Output
===============================================================================
*/

/*excel*/
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
%export_xls(Within_sample_mape4);
%export_xls(out_of_sample_mape4);
%export_xls(WS_OutPut);
%export_xls(OS_OutPut);


/*sas*/
%macro sas_output;
	data output.&lz._OS;
		set OS_Output;
	run;

	data output.&lz._WS;
		set WS_Output;
	run;
%mend;

/*%sas_output;*/


/*
===============================================================================
Save the log and output
===============================================================================
*/
/* Get the current timestamp */
%let log_timestamp = %sysfunc(datetime(), B8601DN.);
/* Save the log and output to a file */
dm "log;    file ""&log_path-&log_timestamp..log"" replace";
dm "output; file ""&log_path-&log_timestamp..lst"" replace";
/* Delete the timestamp macro variable */
%symdel log_timestamp;



