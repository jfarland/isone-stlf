%let dir = C:\Documents and Settings\27513\My Documents\Research\Thesis;

/* Libraries */

libname macros "%superq(dir)\SAS\Macros";
libname rawdat "%superq(dir)\Data";
libname sasdat "%superq(dir)\Data\sasdat";
libname output "%superq(dir)\Output";


options symbolgen;
options spool;

%include "&dir\SAS\Macros\load_forecasting_macros.sas" / source2;
%let lz = region1;	

%let training_beg = '01JAN09 00:00:00'dt;
%let training_end = '31DEC10 23:00:00'dt;

data original;
	set sasdat.&lz;
run;


%make_data_set(original, ds);

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
knotdata=knots_temp,varknots=tempf2);
%default_knots(librefknots=work,data=work.trn,
knotdata=knots_hum,varknots=hum);
%default_knots(librefknots=work,data=work.trn,
knotdata=knots_cc,varknots=cc);
%default_knots(librefknots=work,data=work.trn,
knotdata=knots_ws,varknots=ws);

* This macro creates knots, but rather arbitrarily at every 5;
data trn2;
	set trn;
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

data knotst;
	merge knotst_temp knotst_hum knotst_cc knotst_ws;
	m=1;
run;

/*
===============================================================================
Creating the Z matrix
===============================================================================
*/
data trn3;
	merge trn2 knotst;
	by m;

%let nk1=&nkt_temp;
%let nk2=&nkt_hum;
%let nk3=&nkt_cc;
%let nk4=&nkt_ws;

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
		if Z4a(k) < 0 then Z4a(k)=0;
	end;

drop knots1_1-knots1_&nk1 knots2_1-knots2_&nk2
knots3_1-knots3_&nk3 knots4_1-knots4_&nk4 _name_;
run;

/*
===============================================================================
Fit the model
===============================================================================
*/
ods output CovParms=work.varcomp;
proc mixed data = trn3 noprofile;
model log_load = monday--friday month1-month11 nonworking lag24--lag168 temp hum cc ws  /  solution outp=work.yhat;
	random Z1_1-Z1_&nk1 / type=toep(1) s;
	random Z2_1-Z2_&nk2 / type=toep(1) s;
	random Z3_1-Z3_&nk3 / type=toep(1) s;
	random Z4_1-Z4_&nk4 / type=toep(1) s;
run;

/*
===============================================================================
Calculate MAPE, MAE, MSD for the semilog model
===============================================================================
*/
data mape;
	set yhat(keep=log_load load pred resid hour);
	if pred = '.' then pload = 0; else pload = exp(pred);
		resid = load - pload;
	if resid <0 then resid = resid*-1;
		resid1 = resid/load;
		resid2 = resid1*100;
		resid3 = resid*resid;
proc summary;
	var resid resid2 resid3 ;
	output out = mape2
	   mean=MAE MAPE MSD;
run;

data durbin;
	set mape;
	resid_lag = lag(resid);
proc reg;
model resid = resid_lag;
run;

/*
===============================================================================
Graphics
===============================================================================
*/

ods graphics;
data yhat1;
	set yhat;
	if date ge '01FEB09'd and date le '14FEB09'd;
proc sgplot ;
	series x=datetime y=load ;
	series x=datetime y=pload ;

run;
ods graphics off;

ods graphics on;
proc sgplot data = yhat1;
histogram resid;
density resid;
density resid / type=kernel;
run;
ods graphics off;

ods graphics on;
proc sgplot data = yhat1;
histogram load;
density load;
density load / type=kernel;
run;
ods graphics off;

ods graphics on;
proc sgplot data = yhat1;
histogram log_load;
density log_load;
density log_load / type=kernel;
run;
ods graphics off;



ods graphics on;
proc sgplot data = yhat;
	scatter x = temp y = load;
	series x = temp y = pred;
	series x = temp y = Upper;
	series x = temp y = Lower;
run; 
ods graphics off;

ods graphics on;
proc sgplot data = yhat;
	scatter x = cc y = load;
	scatter x = cc y = pred;
run; 
ods graphics off;

ods graphics on;
proc sgplot data = mape;
	vbox resid2 / category=hour;
run;
ods graphics off;

ods graphics on;
proc sgplot data = yhat;
	scatter x = cc y = load;
	scatter x = cc y = pred;
run; 
ods graphics off;
