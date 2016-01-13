
proc transreg data=ds design;
model pspline(temp / degree=3 nknots=20); 
		*lots of knots;
	id load monday--friday month1-month11 nonworking lag24--lag168 temp hum cc ws;*keeps load in the output dataset;
		output out=tpfsplineout;
		title 'getting cubic TPF basis functions';
run;

proc transreg data=ds design;
model pspline(temp / degree=3 nknots=15); 
		*lots of knots;
	id load monday--friday month1-month11 nonworking lag24--lag168 temp hum cc ws;*keeps load in the output dataset;
		output out=tpfsplineout;
		title 'getting  TPF basis functions';
run;

proc transreg data=ds design;
	model bspline(temp / degree=3 nknots=20);
	id year month date hour datetime load monday--friday month1-month11 nonworking lag24--lag168 temp hum cc ws;
	output out=bsplineout;
	title 'getting cubic b-spline basis functions';
run;
