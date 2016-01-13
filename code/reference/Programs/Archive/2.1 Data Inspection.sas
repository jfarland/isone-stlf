%let dir = C:\Documents and Settings\27513\My Documents\Research\Thesis;

/* Libraries */

libname macros "%superq(dir)\SAS\Macros";
libname rawdat "%superq(dir)\Data";
libname sasdat "%superq(dir)\Data\sasdat";
libname output "%superq(dir)\Output";

options symbolgen;
options spool;

%include "&dir\SAS\Macros\load_forecasting_macros.sas" / source2;
%let lz = nemass1;		


data original;
	set sasdat.&lz;
run;

%make_data_set(original, ds);

%let training_beg = '01JAN09 00:00:00'dt;
%let training_end = '31DEC09 23:00:00'dt;

data trn;
set ds;
if datetime ge &training_beg and datetime le &training_end;
log_load = log(load);
run;
/*
===============================================================================
Determining Knots for 
===============================================================================
*/

%default_knots(librefknots=work,data=work.trn,
knotdata=knots1,varknots=temp);
* This macro creates knots, but rather arbitrarily at every 5;

data kt1;
set work.knots1 nobs=nk1;
call symput('nkt1',nk1);
run;
proc transpose data=work.knots1 prefix=knots1_ out=knotst1;
var knots;
run;


/*
===============================================================================
Build Z Matrix
===============================================================================
*/





/*
===============================================================================
Fit Additive Model
===============================================================================
*/



* Fitting a an additive model;
proc mixed;
model y = x1-x4 / solution outp=paper.yhat;
random Z1_1-Z1_&nk1 / type=toep(1) s;
random Z2_1-Z2_&nk2 / type=toep(1) s;
random Z3_1-Z3_&nk3 / type=toep(1) s;
run;


/*the MIXED Procedure*/

ods graphics on;
proc mixed noprofile data = trn plots(MAXPOINTS=50000)=all ; *noprofile stops the algorithm from profiling;
*out the variance of the error term;
model log_load = month1-month11 nonworking lag24--lag168  / influence solution outp=work.yhat;
random temp / type=toep(1) s;
random hum / type=toep(1) s;
random cc / type=toep(1) s;
random ws / type = toep(1) s;
*specifying residual and smoothing term variance components;
*parms (400) (1) / noiter; *noiter prevents Newton-Raphson iterative;
*algorithm from changing variance components;
*parms (3.2) (2) / noiter;
/*
parms (15) (100) / noiter;
*/
run;
ods graphics off;


proc sgplot data = trn;
pbspline x = lag24 y = log_load;
/*
scatter x = lag48 y = log_load;
scatter x = lag72 y = log_load;
scatter x = lag96 y = log_load;
*/
run;
/* Hyndmand and Fan assumed these relationships to be smooth and used cubic regression splines
	Our data seems to have a pretty linear relationship - incorporate as fixed effects */


/* Compare Predicted vs. Actual */
proc sgplot data = yhat;
series x=datetime y=load ;
series x=datetime y=pred ;
run;
/* Compare Predicted vs. Actual */
proc sgplot data = yhat;
scatter x=date y=resid;
run;

proc sgplot data = yhat;
vbox resid / category=hour;
run;

proc sgplot data = yhat;
  title "Residual Distribution";
  histogram resid;
  density resid;
  density resid / type=kernel;
  keylegend / location=inside position=topright;
run;

proc sgplot;
series x = datetime y = load;
run;

proc sgplot data = yhat;
	scatter x = temp y = load;
	scatter x = temp y = pred;
run; 

proc sgplot data = yhat;
	vbox resid / category=hour;
run;

proc summary data = yhat;
var resid;
output out = err
	   mean = mean_err
	   sum =  sum_err;
run;
data err2;
set err;


proc sgplot data = gam_out;
series x = datetime y = p_load;
series x = datetime y = load;
run;


/*the GLIMMIX Procedure*/

proc glimmix data=spline outdesign=x;
   class group;
   effect spl = spline(x);
   model y = group spl*group / s noint;
   output out=gmxout pred=p;
run;

proc glimmix data = original plots=all;
model load = temp hum;
random temp / type = rsmooth
			  knotmethod=kdtree(bucket=8 treeinfo knotinfo);
random hum / type = rsmooth;

run;



/* the TRANSREG Procedure*/

proc transreg data=region1;
   model identity(load) = pspline(temp) pspline(hum) pspline(ws) pspline(cc);
   output out = region2 predicted;
run;

proc transreg data=A;
      model identity(Y) = spline(X / nknots=9);
      title3 'Nine Knots';
      output out=A pprefix=Cub9k;
      id V1-V7 LinearY QuadY Cub1Y Cub3Y Cub4Y Cub4kY;
   run;



proc transreg data=region1;
   model identity(load) = pspline(temp) pspline(hum) pspline(ws) pspline(cc);
   output out = region2 predicted;
run;


/* the GAM Procedure*/
ods graphics on;
proc gam data = original;
	model load = spline(temp) spline(hum)
				 spline(cc)   spline(ws)/ method = CV;
	output out = gam_out all;
run;
ods graphics off;

/* Graphics/*

proc gplot data = region2;
   plot (load pload)*temp / overlay;
   plot (load pload)*hum / overlay;
   plot (load pload)*cc / overlay;
   plot (load pload)*ws / overlay;
run;



