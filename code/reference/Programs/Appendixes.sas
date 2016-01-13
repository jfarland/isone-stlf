

%macro summarize(lz, output);

	/*initialize data set*/
	data original;
		set sasdat.&lz;
	run;

	/*use macro to create variable constructs from original data set*/
	%make_data_set(original, ds);

	/*summarize*/
	proc summary 
		data = ds n mean std median min max;
		var load temp hum ws cc;
		output
			out = &output;
	run;

	proc transpose
		data = &output
		out  = &output;
		id     _STAT_;
	run;

%mend;

%summarize(region, region_summary);
%summarize(nemass, nemass_summary);
%summarize(semass, semass_summary);
%summarize(wcmass, wcmass_summary);
%summarize(ct, ct_summary);
%summarize(ri, ri_summary);
%summarize(vt, vt_summary);
%summarize(nh, nh_summary);
%summarize(me, me_summary);

/*
===============================================================================
Export results
===============================================================================
*/
%macro export_xls(data);
	proc export
	  data = &data
	  outfile = "C:\Users\jonfar\Documents\Research\Thesis\SAS\Output\dataset summaries.xlsx"
		dbms = excel
	  label replace;
	  sheet = "&data ";
	run;
%mend;

%export_xls(region_summary);
%export_xls(nemass_summary);
%export_xls(semass_summary);
%export_xls(wcmass_summary);
%export_xls(ct_summary);
%export_xls(ri_summary);
%export_xls(vt_summary);
%export_xls(nh_summary);
%export_xls(me_summary);



