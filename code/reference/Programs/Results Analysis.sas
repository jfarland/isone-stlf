/*
===============================================================================
Zonal Model Comparison
===============================================================================
*/


/* SAS data sets */

/* Region */

%let lz = me;

data &lz._OS;
	set output.&lz._OS;
run;

data &lz._WS;
	set output.&lz._WS;
run;


/*
===============================================================================
Within-Sample
===============================================================================
*/


/* Region */
data WS_R;
	format zone $6.;
	set region_ws;
	zone = 'REGION';
run;

data WS_R1;
	set WS_R;

	resid = load - pred;
	if resid = '.' then delete; 

	if resid >0 then abs_error = resid;
	else abs_error = resid*-1;
	
	rel_error = abs_error/load;
	abs_pct_error = rel_error*100;
	abs_squared_error = resid*resid;
run;


/* Load Zones */

data WS_Z;
	format zone $6.;
	set ri_ws(in=_1) ct_ws(in=_2) wcmass_ws(in=_3) nemass_ws(in=_4) semass_ws(in=_5) vt_ws(in=_6) nh_ws(in=_7) me_ws(in=_8);
	if _1 then zone = 'RI';
	if _2 then zone = 'CT';
	if _3 then zone = 'WCMASS';
	if _4 then zone = 'NEMASS';
	if _5 then zone = 'SEMASS';
	if _6 then zone = 'VT';
	if _7 then zone = 'NH';
	if _8 then zone = 'ME';
run;


data WS_Z1;
	set WS_Z;

	resid = load - pred;
	if resid = '.' then delete; 

	if resid >0 then abs_error = resid;
	else abs_error = resid*-1;
	
	rel_error = abs_error/load;
	abs_pct_error = rel_error*100;
	abs_squared_error = resid*resid;
run;

/* Forecasting performance for the entire within-sample period */

/* Check results for each zone */

proc sort data = WS_Z1;
	by zone ;
run;
proc summary data = WS_Z1;
	by zone;
	var abs_error abs_pct_error abs_squared_error;
	output out = WS_Z2(drop = _FREQ_ _TYPE_)
	   mean(abs_error)=MAE
	   mean(abs_pct_error)=MAPE
       mean(abs_squared_error)=MSD;
run;


/* Aggregate the Zonal Predictions and Errors */
proc sort data = WS_Z1;
	by year month day hour2;
run;

proc summary data = WS_Z1;
	by year month day hour2;
	var abs_error abs_pct_error abs_squared_error;
	output out = WS_Z3(drop= _FREQ_ _TYPE_)
	   sum(load) = load
	   sum(pred) = pred
	   sum(resid) = resid;
run;

/* Calculate Aggregation Errors*/
data WS_Z4;
	set WS_Z3;

	resid = load - pred;
	if resid = '.' then delete; 

	if resid >0 then abs_error = resid;
	else abs_error = resid*-1;
	
	rel_error = abs_error/load;
	abs_pct_error = rel_error*100;
	abs_squared_error = resid*resid;
run;

/* Calculate Zonal Error Metrics */

/* Overall */
proc summary data = WS_Z4;
	var abs_error abs_pct_error abs_squared_error;
	output out = WS_Z_OVERALL(drop = _FREQ_ _TYPE_)
	   mean(abs_error)=MAE
	   mean(abs_pct_error)=MAPE
       mean(abs_squared_error)=MSD;
run;

/* by hour */
proc sort data = WS_Z4; by hour2; run;

proc summary data = WS_Z4;
by hour2;
	var abs_error abs_pct_error abs_squared_error;
	output out = WS_Z_HOUR(drop = _FREQ_ _TYPE_)
	   mean(abs_error)=MAE
	   mean(abs_pct_error)=MAPE
       mean(abs_squared_error)=MSD;
run;


/* by month */
proc sort data = WS_Z4; by month; run;

proc summary data = WS_Z4;
by month;
	var abs_error abs_pct_error abs_squared_error;
	output out = WS_Z_MONTH(drop = _FREQ_ _TYPE_)
	   mean(abs_error)=MAE
	   mean(abs_pct_error)=MAPE
       mean(abs_squared_error)=MSD;
run;


/* Calculate Regional Error Metrics */

/* Overall */
proc summary data = WS_R1;
	var abs_error abs_pct_error abs_squared_error;
	output out = WS_R_OVERALL(drop = _FREQ_ _TYPE_)
	   mean(abs_error)=MAE
	   mean(abs_pct_error)=MAPE
       mean(abs_squared_error)=MSD;
run;

/* by hour */
proc sort data = WS_R1; by hour2; run;

proc summary data = WS_R1;
by hour2;
	var abs_error abs_pct_error abs_squared_error;
	output out = WS_R_HOUR(drop = _FREQ_ _TYPE_)
	   mean(abs_error)=MAE
	   mean(abs_pct_error)=MAPE
       mean(abs_squared_error)=MSD;
run;

/* by month */
proc sort data = WS_R1; by month; run;

proc summary data = WS_R1;
by month;
	var abs_error abs_pct_error abs_squared_error;
	output out = WS_R_MONTH(drop = _FREQ_ _TYPE_)
	   mean(abs_error)=MAE
	   mean(abs_pct_error)=MAPE
       mean(abs_squared_error)=MSD;
run;

/* Output all metrics to excel */

%SendToExcel3(WS_R_OVERALL,      ResultsWorkbook,"TableData",2,2);
%SendToExcel3(WS_R_MONTH,        ResultsWorkbook,"TableData",5,2);
%SendToExcel3(WS_R_HOUR,         ResultsWorkbook,"TableData",19,2);

%SendToExcel3(WS_Z_OVERALL,      ResultsWorkbook,"TableData",2,7);
%SendToExcel3(WS_Z_MONTH,        ResultsWorkbook,"TableData",5,7);
%SendToExcel3(WS_Z_HOUR,         ResultsWorkbook,"TableData",19,7);


/*
===============================================================================
Out of Sample (2011)
===============================================================================
*/

/* Region */
data OS_R;
	format zone $6.;
	set region_os;
	zone = 'REGION';
run;

data OS_R1;
	set OS_R;

	resid = load - pred;
	if resid = '.' then delete; 

	if resid >0 then abs_error = resid;
	else abs_error = resid*-1;
	
	rel_error = abs_error/load;
	abs_pct_error = rel_error*100;
	abs_squared_error = resid*resid;
run;




/* Load Zones */

data OS_Z;
	format zone $6.;
	set ri_os(in=_1) ct_os(in=_2) wcmass_os(in=_3) nemass_os(in=_4) semass_os(in=_5) vt_os(in=_6) nh_os(in=_7) me_os(in=_8);
	if _1 then zone = 'RI';
	if _2 then zone = 'CT';
	if _3 then zone = 'WCMASS';
	if _4 then zone = 'NEMASS';
	if _5 then zone = 'SEMASS';
	if _6 then zone = 'VT';
	if _7 then zone = 'NH';
	if _8 then zone = 'ME';
run;



data OS_Z1;
	set OS_Z;

	resid = load - pred;
	if resid = '.' then delete; 

	if resid >0 then abs_error = resid;
	else abs_error = resid*-1;
	
	rel_error = abs_error/load;
	abs_pct_error = rel_error*100;
	abs_squared_error = resid*resid;
run;

/* Forecasting performance for the entire within-sample period */

/* Check results for each zone */

proc sort data = OS_Z1;
	by zone ;
run;
proc summary data = OS_Z1;
	by zone;
	var abs_error abs_pct_error abs_squared_error;
	output out = OS_Z2(drop = _FREQ_ _TYPE_)
	   mean(abs_error)=MAE
	   mean(abs_pct_error)=MAPE
       mean(abs_squared_error)=MSD;
run;


/* Aggregate the Zonal Predictions and Errors */
proc sort data = OS_Z1;
	by year month day hour2;
run;

proc summary data = OS_Z1;
	by year month day hour2;
	var abs_error abs_pct_error abs_squared_error;
	output out = OS_Z3(drop= _FREQ_ _TYPE_)
	   sum(load) = load
	   sum(pred) = pred
	   sum(resid) = resid;
run;

/* Calculate Aggregation Errors*/
data OS_Z4;
	set OS_Z3;

	resid = load - pred;
	if resid = '.' then delete; 

	if resid >0 then abs_error = resid;
	else abs_error = resid*-1;
	
	rel_error = abs_error/load;
	abs_pct_error = rel_error*100;
	abs_squared_error = resid*resid;
run;

/* Calculate Zonal Error Metrics */

/* Overall */
proc summary data = OS_Z4;
	var abs_error abs_pct_error abs_squared_error;
	output out = OS_Z_OVERALL(drop = _FREQ_ _TYPE_)
	   mean(abs_error)=MAE
	   mean(abs_pct_error)=MAPE
       mean(abs_squared_error)=MSD;
run;

/* by hour */
proc sort data = OS_Z4; by hour2; run;

proc summary data = OS_Z4;
by hour2;
	var abs_error abs_pct_error abs_squared_error;
	output out = OS_Z_HOUR(drop = _FREQ_ _TYPE_)
	   mean(abs_error)=MAE
	   mean(abs_pct_error)=MAPE
       mean(abs_squared_error)=MSD;
run;


/* by month */
proc sort data = OS_Z4; by month; run;

proc summary data = OS_Z4;
by month;
	var abs_error abs_pct_error abs_squared_error;
	output out = OS_Z_MONTH(drop = _FREQ_ _TYPE_)
	   mean(abs_error)=MAE
	   mean(abs_pct_error)=MAPE
       mean(abs_squared_error)=MSD;
run;


/* Calculate Regional Error Metrics */

/* Overall */
proc summary data = OS_R1;
	var abs_error abs_pct_error abs_squared_error;
	output out = OS_R_OVERALL(drop = _FREQ_ _TYPE_)
	   mean(abs_error)=MAE
	   mean(abs_pct_error)=MAPE
       mean(abs_squared_error)=MSD;
run;

/* by hour */
proc sort data = OS_R1; by hour2; run;

proc summary data = OS_R1;
by hour2;
	var abs_error abs_pct_error abs_squared_error;
	output out = OS_R_HOUR(drop = _FREQ_ _TYPE_)
	   mean(abs_error)=MAE
	   mean(abs_pct_error)=MAPE
       mean(abs_squared_error)=MSD;
run;

/* by month */
proc sort data = OS_R1; by month; run;

proc summary data = OS_R1;
by month;
	var abs_error abs_pct_error abs_squared_error;
	output out = OS_R_MONTH(drop = _FREQ_ _TYPE_)
	   mean(abs_error)=MAE
	   mean(abs_pct_error)=MAPE
       mean(abs_squared_error)=MSD;
run;

/* by day */


proc sort data = OS_R1; by day; run;

proc summary data = OS_R1;
by DAY;
	var abs_error abs_pct_error abs_squared_error;
	output out = OS_R_DAY(drop = _FREQ_ _TYPE_)
	   mean(abs_error)=MAE
	   mean(abs_pct_error)=MAPE
       mean(abs_squared_error)=MSD;
run;


/* Output all metrics to excel */

%SendToExcel3(OS_R_OVERALL,      ResultsWorkbook,"TableData",2,12);
%SendToExcel3(OS_R_MONTH,        ResultsWorkbook,"TableData",5,12);
%SendToExcel3(OS_R_HOUR,         ResultsWorkbook,"TableData",19,12);

%SendToExcel3(OS_Z_OVERALL,      ResultsWorkbook,"TableData",2,17);
%SendToExcel3(OS_Z_MONTH,        ResultsWorkbook,"TableData",5,17);
%SendToExcel3(OS_Z_HOUR,         ResultsWorkbook,"TableData",19,17);



/*
===============================================================================
Plots of Error Breakdown
===============================================================================
*/

/* Determine largest Occurences of Peak Demannd*/
proc summary data = OS_R1;
	by month day;
	var load;
	output out = peak_load
	max(load) = mload
	var(load) = vload;
run;

proc sort data = peak_load;
	by mload;
run;

/* Compare Predicted to Actual */

proc sort data =OS_R1;
	by month day;
run;

proc sort data =peak_load;
	by month day;
run;

data peak_load_pred;
	merge OS_R1(in=x keep = pred resid month day) peak_load(in=y keep=mload month day );
	by month day;
	if y then output;

	keep month day mload pred resid;
run;

/* Error Breakdown */


ods graphics on;
proc sgplot data = OS_Z4 ;
	vbox abs_pct_error / category=hour2;
	yaxis label = "Error Percent" grid;
	xaxis label = "Hour of the Day" grid;
run;
ods graphics off;

ods graphics on;
proc sgplot data = WS_Z4 ;
	vbox abs_pct_error / category=hour2;
	yaxis label = "Error Percent" grid;
	xaxis label = "Hour of the Day" grid;
run;
ods graphics off;

ods graphics on;
proc sgplot data = OS_R1 ;
	vbox abs_pct_error / category=hour2;
	yaxis label = "Error Percent" grid;
	xaxis label = "Hour of the Day" grid;
run;
ods graphics off;

ods graphics on;
proc sgplot data = WS_R1 ;
	vbox abs_pct_error / category=hour2;
	yaxis label = "Error Percent" grid;
	xaxis label = "Hour of the Day" grid;
run;
ods graphics off;

/*
===============================================================================
Plots of Forecasted Load
===============================================================================
*/
proc sort data = OS_R1; by year month day hour2;run;

data OS_R3;
set OS_R1;
format date mmddyy8. datetime datetime17.;
	   date     = mdy(month, day, year);
	   datetime = dhms(date,hour2,0,0);
	   	if date ge '01JUL11'd and date le '07JUL11'd;
run;

proc sort; by datetime;

ods graphics on;
proc sgplot ;
    series x=datetime y=load / LINEATTRS=(color=red thickness=2) legendlabel = 'Actual Load';
	series x=datetime y=pred / LINEATTRS=(color=black thickness=2) legendlabel = 'Forecasted Load';
	series x = datetime y=Upper / LINEATTRS=(color=black pattern=longdash thickness=1) legendlabel = 'Upper 95% Prediction Interval';
	series x = datetime y=Lower/  LINEATTRS=(color=black pattern=longdash thickness=1)legendlabel =  'Lower 95% Prediction Interval';
	keylegend / location=outside position=bottomright;
    xaxis label = "Date" grid;
	yaxis label = "Load (MW)" grid;
	;
run;
ods graphics off;


/* 2011 Peak Load */

proc sort data = OS_R1; by year month day hour2;run;

data OS_R4;
set OS_R1;
format date mmddyy8. datetime datetime17.;
	   date     = mdy(month, day, year);
	   datetime = dhms(date,hour2,0,0);
	   	if date ge '17JUL11'd and date le '23JUL11'd;
run;

proc sort; by datetime;

ods graphics on;
proc sgplot ;
    series x=datetime y=load / LINEATTRS=(color=red thickness=2) legendlabel = 'Actual Load';
	series x=datetime y=pred / LINEATTRS=(color=black thickness=2) legendlabel = 'Forecasted Load';
	series x = datetime y=Upper / LINEATTRS=(color=black pattern=longdash thickness=1) legendlabel = 'Upper 95% Prediction Interval';
	series x = datetime y=Lower/  LINEATTRS=(color=black pattern=longdash thickness=1)legendlabel =  'Lower 95% Prediction Interval';
	keylegend / location=outside position=bottomright;
    xaxis label = "Date" grid;
	yaxis label = "Load (MW)" grid;
	;
run;
ods graphics off;
