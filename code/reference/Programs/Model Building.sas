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

%let lz = region;	

/*
%let trn_ = 20;
*/

data original;
	set sasdat.&lz;
run;

%make_data_set(original, ds);

data simple_regression_data;
	set ds;
if year = 2011;
if month1;
log_load = log(load);
run;

proc sgplot data = simple_regression_data nolegend;
	reg x = temp y = load;
run;


proc reg data = simple_regression_data;
	model load = temp / influence;
run; 



/* Average Load Shapes by Day */
%ps(ds, weekday hour);
ods graphics on;
proc summary data = ds;
 	by    weekday;
 	var   load;
 	class hour;
 		output out  = WeekDay_Avgs
               mean = AverageLoad;
run;


/* Assign format for weekdays for graphs below */
/* As of March 27th, 2013- this won't work because it is exactly what SAS made 1-7 already */
proc format;
	value weekday 1='Sunday'
				  2='Monday'
				  3='Tuesday'
				  4='Wednesday'
				  5='Thursday'
				  6='Friday'
				  7='Saturday';
run;

ods graphics on;
ods html style = statistical;
proc sgpanel data = WeekDay_Avgs noautolegend;
	panelby weekday / columns = 4 rows=2;
	series x=Hour y=AverageLoad ;
	colaxis label = "Hour of the Day";
	rowaxis label = "Average Demand";
run;
ods html off;
ods graphics off;

/* Nonworking day avg versus working day avg */
proc sort data =ds; by nonworking hour; run;
proc summary data = ds;
	by nonworking;
	var load;
	class hour;
		output out = test1
			   mean = TheAverage;
run;

data test2;
	set test1;
	format group $10.;
	if nonworking = 0 then Day = 'Working';
	else Day = 'Nonworking';
run;


ods graphics on;
ods html style =statistical;
proc sgplot data = test2;
	series x = hour y = TheAverage / group=Day legendlabel = 'Day Type';
	xaxis label = "Hour of the Day" grid;
	yaxis label = "Average Demand" grid;
run;
ods html close;
ods graphics off;


/* Monthly Effects */
%ps(ds, month hour);
ods output statistics = work.stats;
proc ttest data = ds;
	by month hour;
	var load;
run;

data stats2;
	set stats;
	format effect $9.;
	if month = 1 then effect = 'Jan';
	else if month = 2 then effect = 'Feb';
	else if month = 3 then effect = 'Mar';
	else if month = 4 then effect = 'Apr';
	else if month = 5 then effect = 'May';
	else if month = 6 then effect = 'Jun';
	else if month = 7 then effect = 'Jul';
	else if month = 8 then effect = 'Aug';
	else if month = 9 then effect = 'Sep';
	else if month = 10 then effect = 'Oct';
	else if month = 11 then effect = 'Nov';
	else if month = 12 then effect = 'Dec';
drop month;
rename effect = month;

run;

ods graphics on;
ods html style = statistical;
proc sgpanel data = stats noautolegend;
	panelby month / columns = 6 rows=2;
	series x=hour y=mean ;
	series x=hour y=LowerClMean;
	series x=hour y=UpperCLMean;
	colaxis label = "Hour of the Day" grid;
	rowaxis label = "Average Demand" grid;
run;
ods html off;
ods graphics off;

%ps(ds, month year);
data ds2; set ds1; if year = 2012 then delete; run;

ods output statistics = work.year_mo_stats;
proc ttest data = ds2;
	by month year;
	var load;
run;

/* Rename the months */
data mo_effects;
	set year_mo_stats;
	format effect $9.;
	if month = 1 then effect = 'January';
	else if month = 2 then effect = 'February';
	else if month = 3 then effect = 'March';
	else if month = 4 then effect = 'April';
	else if month = 5 then effect = 'May';
	else if month = 6 then effect = 'June';
	else if month = 7 then effect = 'July';
	else if month = 8 then effect = 'August';
	else if month = 9 then effect = 'September';
	else if month = 10 then effect = 'October';
	else if month = 11 then effect = 'November';
	else if month = 12 then effect = 'December';
run;

%ps(mo_effects, year month);
ods graphics on;
ods html style = statistical;
proc sgpanel data = mo_effects;
panelby year / columns = 1 rows=3;
	scatter x = effect y = mean;
	series x = effect y = LowerCLMean;
	series x= effect y = UpperCLMean;
	colaxis label = "Month of the Year" grid;
	rowaxis label = "Average Demand" grid;
run;
ods html close;
ods graphics off;



proc sgscatter data = ds;
by year;
	matrix compare ;
run;


/*
===============================================================================
 Lagged Load Relationships 
===============================================================================
*/


/* Lagged 48 Hours */
ods graphics on;
ods html style = statistical;
proc sgplot data = ds;
	scatter x=lag48 y=load ;
	xaxis label = "48-Hour Lagged Demand";
	yaxis label = "Electricity Demand";
run;
ods html off;
ods graphics off;

/* Lagged 72 Hours */
ods graphics on;
ods html style = statistical;
proc sgplot data = ds;
	scatter x=lag72 y=load ;
	xaxis label = "72-Hour Lagged Demand";
	yaxis label = "Electricity Demand";
run;
ods html off;
ods graphics off;

/* Lagged 96 Hours */
ods graphics on;
ods html style = statistical;
proc sgplot data = ds;
	scatter x=lag96 y=load ;
	xaxis label = "96-Hour Lagged Demand";
	yaxis label = "Electricity Demand";
run;
ods html off;
ods graphics off;

/* Lagged 120 Hours */
ods graphics on;
ods html style = statistical;
proc sgplot data = ds;
	scatter x=lag120 y=load ;
	xaxis label = "120-Hour Lagged Demand";
	yaxis label = "Electricity Demand";
run;
title;
ods html off;
ods graphics off;

/* Lagged 144 Hours */
ods graphics on;
ods html style = statistical;
proc sgplot data = ds;
	scatter x=lag144 y=load ;
	xaxis label = "144-Hour Lagged Demand";
	yaxis label = "Electricity Demand";
run;
title;
ods html off;
ods graphics off;

/* Lagged 168 Hours */
ods graphics on;
ods html style = statistical;
proc sgplot data = ds;
	scatter x=lag168 y=load ;
	xaxis label = "168-Hour Lagged Demand";
	yaxis label = "Electricity Demand";
run;
title;
ods html off;
ods graphics off;

/*
===============================================================================
Plot Weather Predictors
===============================================================================
*/

/* Plot actual load */
ods graphics on / ANTIALIASMAX=8800;
ods html style = statistical;
data original_year;
	set original;
	if year = 2010; 

proc sgplot data = original_year;

	series x = datetime y = load;
	xaxis label = "Time" grid;
	yaxis label = "Load (MW)" grid;
run;
ods html off;
ods graphics off;


ods graphics on / ANTIALIASMAX=88000;
ods html style = statistical;
data july_all;
	set original;
	if month = 7 and year = 2011;
	if zone ne 'region';
run;
%ps(july_all, zone datetime);
proc sgpanel data = july_all;
panelby zone/ columns = 2 rows = 4;
	series x = datetime y = load;
	colaxis label = "Time" grid  min = '01JUL11:00:00:00'dt max = '31JUL11:00:00:00'dt ;
	rowaxis label = "Load (MW)" grid;
run;
ods html off;
ods graphics off;



data original_season;
	set original;
	format season $6.;

	if month in (1 2 12) then season = 'winter';
	else if month in (3 4 5) then season = 'spring';
	else if month in (6 7 8) then season = 'summer';
	else if month in (9 10 11) then season = 'fall';
ods graphics on;
ods html style = statistical;

proc sgpanel data =original_season;
panelby season;
	scatter x=temp y= load;
	colaxis label = "Temperature in Degrees Fahrenheit" grid;
	rowaxis label = "Load (MW)" grid;
run;
ods html off;
ods graphics on;

proc sgpanel data =original_season;
panelby season;
	scatter x=hum y= load;
	colaxis label = "Dewpoint Temperature in Degrees Fahrenheit" grid;
	rowaxis label = "Load (MW)" grid;
run;
ods html off;
ods graphics on;

data original_season_thi;
	set original_season;
	thi = 15 + .5*temp + .3*hum;
run;

proc sgpanel data =original_season_thi;
panelby season;
	scatter x=thi y= load;
	colaxis label = "THI in Degrees Fahrenheit" grid;
	rowaxis label = "Load (MW)" grid;
run;


proc sgpanel data =original_season_thi;
panelby season;
	scatter x=ws y= load;
	colaxis label = "THI in Degrees Fahrenheit" grid;
	rowaxis label = "Load (MW)" grid;
run;




ods graphics on;
ods html style = statistical;
proc sgplot data = original;
	scatter x = temp y = load / markerattrs=(color=black size=5);
	xaxis label = "Temperature in Degrees Fahrenheit" grid;
	yaxis label = "Load (MW)" grid;
run;
ods html off;
ods graphics on;

ods graphics on;
ods html style = statistical;
proc sgplot data = original;
	scatter x = hum y = load /markerattrs=(color=black size=5);
	xaxis label = "Humidity (Dewpoint)" grid;
	yaxis label = "Load (MW)" grid;
run;
ods html off;
ods graphics on;

ods graphics on;
ods html style = statistical;
proc sgplot data = original;
	scatter x = ws y = load/markerattrs=(color=black size=5);
	xaxis label = "Wind Speed (MPH)" grid;
	yaxis label = "Load (MW)" grid;
run;
ods html off;
ods graphics on;

ods graphics on;
ods html style = statistical;
proc sgplot data = original;
	scatter x = cc y = load/markerattrs=(color=black size=5);
	xaxis label = "Cloud Cover as a Proportion of Sky Concealment" grid;
	yaxis label = "Load (MW)" grid;
run;
ods html off;
ods graphics on;




/* Autocorrelation Function */
/* One way to do it involves Proc ARIMA*/
ods listing;
ods html style = statistical;
ods graphics on;
proc arima data = ds plots(unpack)=(series(all)) out = autocorr1;
	identify var = load  nlag = 96;
run;
ods graphics off;
ods html close;


/* Another way to do it involves proc timeseries */
proc timeseries data =ds
				outcorr = acf;
var load;
			corr acov acf ACFSTD acfprob acf2std acfnorm pacf LAG /nlag=200;
run;
data acf; set acf; cl = acfstd*2; upper = acf+cl; lower = acf-cl; if lag = 0 then delete;run;


* Plot autocorrelations;
ods listing;
ods html style = statistical;
ods graphics on;
proc sgplot data = acf;
   scatter x = lag y = acf / legendlabel = "Autocorrelations";
   series  x = lag y = upper /lineattrs= (color = black) legendlabel = "95% Upper Confidence Limit";
   series  x = lag y = lower /lineattrs= (color = black) legendlabel = "95% Lower Confidence Limit";
   yaxis values = (-1 to 1 by .1);
   xaxis values = (0 to 169 by 24) grid;
  run;
ods graphics off;
ods html close;

ods listing;
ods html style = statistical;
ods graphics on;
proc sgscatter data = ds;
	compare x=(lag48--lag96)
			y=(load);
		
run;
ods graphics off;
ods html close;



/* Correlation coefficients */
proc corr data=ds pearson spearman kendall hoeffding;
   var load lag24 lag48 lag72 lag96 lag120 lag144 lag168;
run;

proc corr data = ds pearson spearman kendall hoeffding;
	var load temp hum ws cc;
run;


/* plots of temperature versus load */
ods graphics on;
ods html style = statistical;
proc sgplot data = ds;
   scatter x = temp y = load;
   yaxis max = 30000 min = 0 label="Load (MW)";
   xaxis max = 110 min = -5 label="Drybulb Temperature";
run;


/* Calculate a single knot and display the broken stick model */
data broken_stick_basis;
	set ds;
	knot1 = 65;
	 temp_basis_1 = temp - knot1;
	if temp_basis_1 < 0 then temp_basis_1 = 0;
	drop knot1;
	keep load temp temp_basis_1;
run;

ods listing;
ods html;

proc reg data = broken_stick_basis;
	model load = temp temp_basis_1 / p;
	output out = model_1
		   predicted = pload;
run;
ods graphics on;
ods html style = statistical;
proc sgplot data = model_1;

   scatter x = temp y = load;
   scatter x = temp y = pload;
   yaxis max = 30000 min = 0 label = "Load (MW)";
   xaxis max = 110 min = -5 label= "Drybulb Temperature";
run;

ods html close;
ods graphics off;
/* Calculate a single knot and display the broken stick model */


data broken_stick_basis_2;
	set ds;
	knot1 = 20;
	knot2 = 40;
	knot3 = 60;
	knot4 = 80;
	 temp_basis_1 = temp - knot1;
	if temp_basis_1 < 0 then temp_basis_1 = 0;
	 temp_basis_2 = temp - knot2;
	if temp_basis_2 < 0 then temp_basis_2 = 0;
 	 temp_basis_3 = temp - knot3;
	if temp_basis_3 < 0 then temp_basis_3 = 0;
	 temp_basis_4 = temp - knot4;
	if temp_basis_4 < 0 then temp_basis_4 = 0;

	drop knot1-knot4;
	keep load temp temp_basis_1-temp_basis_4;
run;

proc reg data = broken_stick_basis_2 plots(only)=none noprint;
	model load = temp temp_basis_1-temp_basis_4 / p;
	output out = model_2
		   predicted = pload;
run;

ods listing;
ods graphics on / ANTIALIASMAX=30000;
ods html style = statistical;
proc sgplot data = model_2;

   scatter x = temp y = load;
   scatter x = temp y = pload;
   yaxis max = 30000 min = 0 label = "Load (MW)";
   xaxis max = 110 min = -5 label= "Drybulb Temperature";
run;

ods html close;
ods graphics off;

/* Calculate the same fit but with more knots */

%default_knots(librefknots=work,data=work.ds,
knotdata=knots_temp,varknots=temp);

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

data knotst;
	set knotst_temp;
	m=1;
run;

/* Linear Spline with Four Knots */

data mixed;
	merge ds2 knotst;
		by m;
		%let nk=&nkt_temp;
	array Z (&nk) Z1-Z&nk;
	array knots (&nk) knots_temp_1-knots_temp_&nk;
	do k=1 to &nk;
		Z(k)=temp-knots(k);
		if Z(k) < 0 then Z(k)=0;
	end;
	drop knots1-knots&nk _name_;
run;

ods output;
proc reg data = mixed;
	model load = temp Z1-Z&nk;
	output out = model_3
	       predicted = pload;
run;

ods graphics on;
ods html style = statistical;
proc sgplot data = model_3;

   scatter x = temp y = load;
   scatter x = temp y = pload;
   yaxis max = 30000 min = 0 label = "Load (MW)";
   xaxis max = 110   min = -5 label= "Drybulb Temperature";
run;

ods html close;
ods graphics off;


/* Smoothing Spline */

proc transreg data = mixed;
	model identity(load) = smooth(temp);
	output out = smoothing_spline
		   predicted;
run;
ods graphics on;
ods html style = statistical;
proc sgplot data = smoothing_spline;
title "Smoothing Spline of Temperature";
title2 "K = All Data Points";
   scatter x = temp y = load;
   scatter x = temp y = pload /MARKERATTRS=(size=12) ;
   yaxis max = 30000 min = 0 label = "Load (MW)";
   xaxis max = 110 min = -5 label= "Drybulb Temperature";
run;
title;
title2;
ods html close;
ods graphics off;


/* Penalized Spline */

ods output CovParms=work.varcomp;
proc mixed data = mixed;
	model load = temp / solution outp=work.yhat;
	random Z1-Z&nk / type=toep(1) s;
run;

ods graphics on;
ods html style = statistical;
proc sgplot data = yhat;
title "Penalized Spline of Temperature";
title2 "K = 21 knots";
   scatter x = temp y = load;
   scatter x = temp y = pred;
   yaxis max = 30000 min = 0 label = "Load (MW)";
   xaxis max = 110 min = -5 label= "Drybulb Temperature";
run;
title;
title2;
ods html close;
ods graphics off;

/* Other Weather Variables*/


proc sgplot data = ds;
	scatter x = ws y = load;
run;



/* Run polynomial regression just on temperature*/

ods graphics on;
proc reg data = ds;
	model load =  temp tempsqr tempcub;
    output out = model_4
		   predicted = pload;
run;




proc sgplot data = ds;
	series x = datetime y = load;
run;







