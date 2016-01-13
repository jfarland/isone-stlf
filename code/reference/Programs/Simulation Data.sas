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

%let lz = wcmass;	

/*
%let trn_ = 20;
*/

data original;
	set sasdat.&lz;
run;

%make_data_set(original, ds);

/* Linear Data */

data summer_data;
	set ds;
	if month ge 6 and month le 8;
	if year = 2011;
run;

proc corr data = summer_data pearson;
var temp load;
run;


ods html style = statistical;
proc sgplot data = summer_data;
	scatter x = temp y = load / markerattrs=(color=black size=5);;
	yaxis label = "Electricity Demand (MW)" grid;
	xaxis label = "Temperature in Degrees Fahrenheit" grid;
run;

proc reg data = summer_data;
	model load = temp / dwprob clb acov spec vif collin hcc white;
	output out = summer_output
	   p   = pred
	   r   = err;
run;

proc sgplot data = summer_output;
	scatter x = temp y = load / markerattrs=(color=black size=5); ;
	/*scatter x = temp y = pred / markerattrs=(color=red symbol =circleFilled size=5);*/
	series  x = temp y = pred / lineattrs=(color = red thickness=2) legendlabel = "Predicted Value of Load" ;
	yaxis label = "Electricity Demand (MW)" grid;
	xaxis label = "Temperature in Degrees Fahrenheit" grid;

run;

proc sgplot data = summer_output;
	histogram err;
	density err;
run;

/* Nonlinear Data */

data annual_data;
	set ds;
	if year = 2011;
	tempsqr=temp**2;
run;

proc corr data = annual_data pearson;
var temp load;
run;

data annual_data1;
	set annual_data;
	if month ge 6 and month le 8;
	if year = 2011;
ods html style = statistical;
proc sgplot ;
	scatter x = temp y = load  / markerattrs=(color=black size=5); ;
	/*scatter x = temp y = pred / markerattrs=(color=red symbol =circleFilled size=5);*/
	/*series  x = temp y = pred / lineattrs=(color = red thickness=2) legendlabel = "Predicted Value of Load" ;*/
	yaxis label = "Electricity Demand (MW)" grid;
	xaxis label = "Temperature in Degrees Fahrenheit" grid values = (-10 to 100 by 10);
run;

proc sgplot data = annual_data ;
	scatter x = temp y = load / markerattrs=(color=black size=5);;
	/*scatter x = temp y = pred / markerattrs=(color=red symbol =circleFilled size=5);*/
	/*series  x = temp y = pred / lineattrs=(color = red thickness=2) legendlabel = "Predicted Value of Load" ;*/
	yaxis label = "Electricity Demand (MW)" grid;
	xaxis label = "Temperature in Degrees Fahrenheit" grid values = (-10 to 100 by 10);
run;


/* Linear Model */

proc reg data = annual_data  PLOTS(MAXPOINTS=100000);
model load = temp / dwprob clb acov spec vif collin hcc white;
output out = annual_output
	   p   = pred
	   r   = err;
run;

proc sgplot data = annual_output;
	scatter x = temp y = load / markerattrs=(color=black size=5);
	series x = temp y = pred/ lineattrs = (color=red thickness=2) legendlabel = "Predicted Value of Load";
	yaxis label = "Electricity Demand (MW)" grid;
	xaxis label = "Temperature in Degrees Fahrenheit" grid values = (-10 to 100 by 10);
run;

/* Quadratic Model */
proc reg data = annual_data  PLOTS(MAXPOINTS=100000);
model load = temp tempsqr/ dwprob clb acov spec vif collin hcc white;
output out = annual_output
	   p   = pred
	   r   = err;
run;

proc sgplot data = annual_output;
	scatter x = temp y = load / markerattrs=(color=black size=5);
	series x = temp y = pred/ lineattrs = (color=red thickness=2) legendlabel = "Predicted Value of Load";
	yaxis label = "Electricity Demand (MW)" grid;
	xaxis label = "Temperature in Degrees Fahrenheit" grid values = (-10 to 100 by 10);
run;




/* Calculate a single knot and display the broken stick model */
data broken_stick_basis;
	set annual_data;
	knot1 = 65;
	 temp_basis_1 = temp - knot1;
	if temp_basis_1 < 0 then temp_basis_1 = 0;
	drop knot1;
	keep load temp temp_basis_1 ;
run;

proc reg data = broken_stick_basis;

	model load = temp temp_basis_1 / dwprob clb acov spec vif collin hcc white;
	output out = single_knot
		   p   = predicted
		   r   = err;
run;
/*Plot*/

proc sgplot data = single_knot;
	scatter x = temp y = load / markerattrs=(color=black size=5);
	series x = temp y = predicted/ lineattrs = (color=red thickness=2) legendlabel = "Predicted Value of Load";
	yaxis label = "Electricity Demand (MW)" grid;
	xaxis label = "Temperature in Degrees Fahrenheit" grid values = (-10 to 100 by 10);
run;


data broken_stick_basis_2;
	set annual_data;
	knot1 = 5;
	knot2 = 25;
	knot3 = 45;
	knot4 = 65;
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

proc reg data = broken_stick_basis_2 ;
	model load = temp temp_basis_1-temp_basis_4 /dwprob clb acov spec vif collin hcc white;
	output out = model_2
		   p = predicted
		   r = error;
run;


proc sgplot data = model_2;
	scatter x = temp y = load / markerattrs=(color=black size=5);
	series x = temp y = predicted/ lineattrs = (color=red thickness=2) legendlabel = "Predicted Value of Load";
	yaxis label = "Electricity Demand (MW)" grid;
	xaxis label = "Temperature in Degrees Fahrenheit" grid values = (-10 to 100 by 10);
run;


/* Basis Displays */

/* Linear Spline with 20 Knots */

data many_knots;
	set annual_data;
	knot1 = 0;
	knot2 = 5;
	knot3 = 10;
	knot4 = 15;
	knot5 = 20;
	knot6 = 25;
	knot7 = 30;
	knot8 = 35;
	knot9 = 40;
	knot10 = 45;
	knot11 = 50;
	knot12 = 55;
	knot13 = 60;
	knot14 = 65;
	knot15 = 70;
	knot16 = 75;
	knot17 = 80;
	knot18 = 85;
	knot19 = 90;
	knot20 = 95;

	 temp_basis_1 = temp - knot1;
	if temp_basis_1 < 0 then temp_basis_1 = 0;
	 temp_basis_2 = temp - knot2;
	if temp_basis_2 < 0 then temp_basis_2 = 0;
 	 temp_basis_3 = temp - knot3;
	if temp_basis_3 < 0 then temp_basis_3 = 0;
	 temp_basis_4 = temp - knot4;
	if temp_basis_4 < 0 then temp_basis_4 = 0;
	 temp_basis_5 = temp - knot5;
	if temp_basis_5 < 0 then temp_basis_5 = 0;
		temp_basis_6 = temp - knot6;
	if temp_basis_6 < 0 then temp_basis_6 = 0;
	 temp_basis_7 = temp - knot7;
	if temp_basis_7 < 0 then temp_basis_7 = 0;
 	 temp_basis_8 = temp - knot8;
	if temp_basis_8 < 0 then temp_basis_8 = 0;
	 temp_basis_9 = temp - knot9;
	if temp_basis_9 < 0 then temp_basis_9 = 0;
	 temp_basis_10 = temp - knot10;
	if temp_basis_10 < 0 then temp_basis_10 = 0;

	 temp_basis_11 = temp - knot11;
	if temp_basis_11 < 0 then temp_basis_11 = 0;
	 temp_basis_12 = temp - knot12;
	if temp_basis_12 < 0 then temp_basis_12 = 0;
 	 temp_basis_13 = temp - knot13;
	if temp_basis_13 < 0 then temp_basis_13 = 0;
	 temp_basis_14 = temp - knot14;
	if temp_basis_14 < 0 then temp_basis_14 = 0;
	 temp_basis_15 = temp - knot15;
	if temp_basis_15 < 0 then temp_basis_15 = 0;
		temp_basis_16 = temp - knot16;
	if temp_basis_16 < 0 then temp_basis_16 = 0;
	 temp_basis_17 = temp - knot17;
	if temp_basis_17 < 0 then temp_basis_17 = 0;
 	 temp_basis_18 = temp - knot18;
	if temp_basis_18 < 0 then temp_basis_18 = 0;
	 temp_basis_19 = temp - knot19;
	if temp_basis_19 < 0 then temp_basis_19 = 0;
	 temp_basis_20 = temp - knot20;
	if temp_basis_20 < 0 then temp_basis_20 = 0;

	keep load temp temp_basis_1-temp_basis_20;
run;


proc reg data = many_knots ;
	model load = temp temp_basis_1-temp_basis_20 /dwprob clb acov spec vif collin hcc white;
	output out = model_20
		   p = predicted
		   r = error;
run;


proc sgplot data = model_20;
	scatter x = temp y = load / markerattrs=(color=black size=5) ;
	/*scatter x = temp y = predicted / markerattrs=(color=red symbol =circleFilled size=6);*/
	series  x = temp y = predicted / lineattrs=(color = red thickness=2) legendlabel = "Predicted Value of Load" ;
	yaxis label = "Electricity Demand (MW)" grid;
	xaxis label = "Temperature in Degrees Fahrenheit" grid values = (-10 to 100 by 10);
run;

proc mixed data = many_knots;
	model load = temp / solution outp=work.yhat;
	random temp_basis_1-temp_basis_20 / type=toep(1) s;
run;


data yhat2;set yhat;m=1;keep m pred;run;
data model_20_2;set model_20;m=1;run;

/* Merge the two results */
data comparison;
	merge yhat2 model_20_2;
	by m;
run;


/* compare them? */
proc sgscatter data = comparison;
	compare y=(load predicted pred) x=temp;
run;


proc sgplot data = comparison;
	scatter x = temp y = load      / markerattrs=(color=black size=4) ;
	/*scatter x = temp y = pred / markerattrs=(color=red symbol =circleFilled size=6);*/
	series  x = temp y = pred      / lineattrs=(color = red thickness=2) legendlabel = "Predicted Value of Load" ;
	series  x = temp y = predicted / lineattrs=(color = green thickness=2) legendlabel = "Predicted Value of Load";
	yaxis label = "Electricity Demand (MW)" grid;
	xaxis label = "Temperature in Degrees Fahrenheit" grid values = (-10 to 100 by 10);
run;










/* Penalized Spline */

%default_knots(librefknots=work,data=work.annual_data,
knotdata=knots_temp,varknots=temp);

data ds2;
	set annual_data;
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

/* Penalized Spline */

data mixed;
	merge ds2 knotst;
		by m;
		%let nk=&nkt_temp;
	array Z (&nk) Z1-Z&nk;
	array knots (&nk) knots_temp_1-knots_temp_&nk;
	do k=1 to &nk;
		Z(k)=(temp-knots(k))**1;*Change number to create polynomial of degree 2 or 3;
		if Z(k) < 0 then Z(k)=0;* Truncate the basis function;
	end;
	drop knots1-knots&nk _name_;
run;
ods output CovParms=work.varcomp;
proc mixed data = mixed;
	model load = temp / solution outp=work.yhat;
	random Z1-Z&nk / type=toep(1) s;
run;


proc sgplot data = yhat;
	scatter x = temp y = load / markerattrs=(color=black size=5) ;
	/*scatter x = temp y = pred / markerattrs=(color=red symbol =circleFilled size=6);*/
	series  x = temp y = pred / lineattrs=(color = red thickness=2) legendlabel = "Predicted Value of Load" ;
	yaxis label = "Electricity Demand (MW)" grid;
	xaxis label = "Temperature in Degrees Fahrenheit" grid values = (-10 to 100 by 10);
run;







/* create base dataset with counter */
data sim1;
do id = 1 to 50;
	output;
end;
run;

/* Simulate data */
data sim2;
	set sim1;
	x = ranuni(27407349);
	e = 0+.1*rannorm(3452083);

	f = sin(-3.14*x)
	y = f+e;
	
run;

ods graphics on;
proc sgplot data = sim2;
	scatter x = x y = y;
run;
ods graphics off;

data sim3;
	set sim2;
	if x le .5 then x1 = x; else x1=0;
	if x ge .5 then x2 = x; else x2=0;
run;

proc reg data = sim3;
	model y = x1 x2;
run;


data sim4;
	set sim3;
	knot1 = .5;
	knot2 = 
	 x1 = x - knot1;
	if x1 < 0 then x1 = 0;
	drop knot1;
	keep y x x1;
run;

ods listing;
ods html;

proc reg data = sim4;
	model y = x x1 / p;
	output out = x1
		   predicted = py;
run;
proc sort data = x1; by x; run;

ods graphics on;
ods html style = statistical;
proc sgplot data = x1;

   scatter x = x y = y;
   series x = x y = py;
run;

ods html close;
ods graphics off;
