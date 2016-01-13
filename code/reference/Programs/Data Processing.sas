
%let dir = C:\Documents and Settings\27513\My Documents\Research\Thesis;

/* Libraries */

libname macros "%superq(dir)\SAS\Macros";
libname rawdat "%superq(dir)\Data";
libname sasdat "%superq(dir)\Data\sasdat";

%include "&dir\SAS\Macros\import-text-files.sas" / source2;

options symbolgen;

%list_files
( path = C:\Documents and Settings\27513\My Documents\Research\Thesis\Data
, out  = list
);


/*
===============================================================================
Some files should be excluded such as "Experiment files"
===============================================================================
*/


data list_filtered;
	set list;
	/* exclude unwanted */
	format zone $50.;
	zone = scan(file,1,'.');
/*
	if index(device, 'experiment')
		then delete; */
run;


/*
===============================================================================
Import and stack CSV files
===============================================================================
*/

proc import out = VT
datafile = "C:\Documents and Settings\27513\My Documents\Research\Thesis\Data\VT.csv"
dbms = CSV replace;
run;

data VT1;
   set VT;
	zone     = 'vt';
   format date mmddyy8. datetime datetime17.;
	date     = mdy(month, day, year);
	datetime = dhms(date,hour,0,0);
proc sort;
by datetime;
run;

proc import out = MAINE
datafile = "C:\Documents and Settings\27513\My Documents\Research\Thesis\Data\MAINE.csv"
dbms = CSV replace;
run;
data ME1;
   set MAINE;
	zone     = 'me';
   format date mmddyy8. datetime datetime17.;
	date     = mdy(month, day, year);
	datetime = dhms(date,hour,0,0);
proc sort;
by datetime;
run;


proc import out = NEMASS
datafile = "C:\Documents and Settings\27513\My Documents\Research\Thesis\Data\NEMASS.csv"
dbms = CSV replace;
run;
data NEMASS1;
   set NEMASS;
	zone     = 'nemass';
   format date mmddyy8. datetime datetime17.;
	date     = mdy(month, day, year);
	datetime = dhms(date,hour,0,0);
proc sort;
by datetime;
run;


proc import out = NH
datafile = "C:\Documents and Settings\27513\My Documents\Research\Thesis\Data\NH.csv"
dbms = CSV replace;
run;
data NH1;
   set NH;
	zone     = 'nh';
   format date mmddyy8. datetime datetime17.;
	date     = mdy(month, day, year);
	datetime = dhms(date,hour,0,0);
proc sort;
by datetime;
run;


proc import out = REGION
datafile = "C:\Documents and Settings\27513\My Documents\Research\Thesis\Data\REGION.csv"
dbms = CSV replace;
run;
data REGION1;
   set REGION;
	zone     = 'region';
   format date mmddyy8. datetime datetime17.;
	date     = mdy(month, day, year);
	datetime = dhms(date,hour,0,0);
proc sort;
by datetime;
run;

proc import out = RI
datafile = "C:\Documents and Settings\27513\My Documents\Research\Thesis\Data\RI.csv"
dbms = CSV replace;
run;
data RI1;
   set RI;
	zone     = 'ri';
   format date mmddyy8. datetime datetime17.;
	date     = mdy(month, day, year);
	datetime = dhms(date,hour,0,0);
proc sort;
by datetime;
run;

proc import out = SEMASS
datafile = "C:\Documents and Settings\27513\My Documents\Research\Thesis\Data\SEMASS.csv"
dbms = CSV replace;
run;
data SEMASS1;
   set SEMASS;
	zone     = 'semass';
   format date mmddyy8. datetime datetime17.;
	date     = mdy(month, day, year);
	datetime = dhms(date,hour,0,0);
proc sort;
by datetime;
run;

proc import out = WCMASS
datafile = "C:\Documents and Settings\27513\My Documents\Research\Thesis\Data\WCMASS.csv"
dbms = CSV replace;
run;
data WCMASS1;
   set WCMASS;
	zone     = 'wcmass';
   format date mmddyy8. datetime datetime17.;
	date     = mdy(month, day, year);
	datetime = dhms(date,hour,0,0);
proc sort;
by datetime;
run;

proc import out = CT
datafile = "C:\Documents and Settings\27513\My Documents\Research\Thesis\Data\Connecticut.csv"
dbms = CSV replace;
run;
data CT1;
   set CT;
	zone     = 'ct';
   format date mmddyy8. datetime datetime17.;
	date     = mdy(month, day, year);
	datetime = dhms(date,hour,0,0);
proc sort;
by datetime;
run;

data load_data;
	set wcmass1
		nemass1
		semass1
		vt1
		nh1
		me1
		ct1
		ri1
		region1;
run;

proc datasets nolist;
 copy in = work out = sasdat;
	select wcmass1
		   nemass1
		   semass1
		   vt1
		   nh1
		   me1
		   ct1
		   ri1
		   region1
		   load_data;
run;

