libname r2r "/home/u35232324/r2r";

/* Part A: Data Setup */
* 1. Health data;
data b_msp; 
	set r2r.msp;
	rename phnnum = phn diagcd = diagcd1 toservdt = servdate;
	drop clnt: fit:;
run;
data b_nacrs; set r2r.nacrs; drop dob gender; run;
data b_dad; set r2r.dad; drop dob gender; run;
data b_pnet; 
	set r2r.pnet; 
	rx_enddate = srv_date + acpt_days_sply;
	rename clnt_key = phn srv_date = servdate;
	format srv_date date9. rx_enddate date9.;
run;
proc sort data=b_msp; by phn servdate; run;
proc sort data=b_nacrs; by phn regdate; run;
proc sort data=b_dad; by phn addate; run;
proc sort data=b_pnet; by phn servdate; run;

* 1. Cohort exposed to R2R;
data a_tte01; 
	set r2r.df;
	rename bc_phn = phn date_of_r2r_admission = r2rdate;
	if in_study_period = 1;
	keep bc_phn date_of_r2r_admission; 
run;
proc sort data=a_tte01; by phn; run;

* 2. Restrict to people who are alive or died after SUD identification;
data a_tte02; set r2r.sud; if deathdate = . or suddate <= deathdate; run;

* 3. Merge data;
data a_tte03;
	merge a_tte01(in = x) a_tte02(in = y keep = phn suddate);
	by phn;
	if x = 1;
	format r2rdate date9.;
	if suddate ne .;
run;
proc sort data=a_tte03; by phn suddate; run;
proc sort data=a_tte03 nodupkey; by phn; run;

* 4. Identify SUD relapse;
/* data r2r.relapse; set a_data02; run; */
data a_tte04; set r2r.relapse; by phn; if first.phn then delete; rename suddate=relapse_date; run;

* 5. Merge data;
data a_tte05;
	merge a_tte03(in = x) a_tte04(in = y);
	by phn;
	if x = 1;
	/* For now, just keep the ones that have follow-up longer than 0 */
	if relapse_date - r2rdate > 0 or relapse_date - r2rdate = .; /* n = 121 */
	if relapse_date = . then do;
		outcome = 0;
		eof_date = intnx('year', r2rdate, 1, 'same') - 1;
	end;
	else do;
		outcome = 1;
		eof_date = relapse_date;
	end;
	format eof_date date9.;
	followup = floor(eof_date - r2rdate);
	f_yr = followup / 365.25;
	/* Set random seed for reproducibility */
    call streaminit(12345); 
    /* Assigns 1 with probability 0.5, and 0 otherwise */
    group = rand("Bernoulli", 0.5);
run;
proc sort data=a_tte05 nodupkey; by phn; run;

/* Part B: Time-to-Event Analysis */
* 1. Sum up the number of events and person-years for each exposure category;
proc means data=a_tte05; var outcome f_yr; class group; output out=b_tte01 sum=event py; quit;

* 2. Calculate incidence rate;
data b_tte02;
	set b_tte01;
	IR = event / (py/1000);
	LCI = quantile('chisq', 0.025, event*2) / ((py/1000)*2);
	UCI = quantile('chisq', 0.975, (event + 1)*2) / ((py/1000)*2);
run;
proc print data=b_tte02; run;

* 3. Cox PH model;
proc phreg data=a_tte05 fast;
	class group (ref="0");
	model followup*outcome(0) = group/risklimits alpha=0.05;
run;


/* Part C: Setup for OAT Study */
* 1. Include everyone in R2R;
data c_oat01; 
	set r2r.df; 
	post_end = intnx('month', index_date, 3, 'same');
	if in_study_period = 1; 
	rename bc_phn = phn; 
run;
proc sort data=c_oat01; by phn; run;

* 2. PNET records for everyone in R2R;
data c_oat02; merge c_oat01(in = a) b_pnet(in = b); by phn; if a = 1; run;

* 3. Identify OAT;
data c_oat03;
	set c_oat02;
	length oat 8;
    oat = 0;
    /* 1. Methadone Maintenance (PINs) */
    if din_pin in (
    	999792, 999793, 66999990, 66999991, 66999992, 66999993,
        66999997, 66999998, 66999999, 67000000,
        67000001, 67000002, 67000003, 67000004,
        67000005, 67000006, 67000007, 67000008,
        67000013, 67000014, 67000015, 67000016, 2394596, 2244290,   
    /* 2. Buprenorphine / Naloxone (Suboxone & Generics) */
    /* Note: Leading zeros dropped (e.g., 02453908 -> 2453908) */
        2295695, 2295709, 2408090, 2408104, 2424851, 2424878,
        2453908, 2453916, 2468085, 2468093, 2502321, 2502348,
        2502356, 2517175,
        2242962, 2242963, 2242964, 66999994, 66999995, 66999996, 2483084, 2483092,
    /* 3. Sublocade (Injectable Buprenorphine) */
        66123367, 2146126, 22123340, 22123357,
    /* 4. Kadian (SROM for OAT) */
        22123349, 22123346, 22123347, 22123348, 22123405,
    /* 5. Transaction Medication Updates (Clinic Admin/Stock) */
        66128342, 66128343, 66128344, 66128345, 66128346
    ) then oat = 1;
    if oat = 1;
    
    /* IMPORTANT: Restrict to prescriptions until follow-up end date! */
   if servdate <= post_end or rx_enddate <= post_end;
   rename date_of_r2r_admission = r2rdate;
   format date_of_r2r_admission date9. post_end date9.;
   drop pre: post_start;
run;

* 4. Restrict to those who had active prescription at R2R (1-day grace period);
** a. First ID;
data c_oat04a; 
	set c_oat03; 
	by phn; 
	if first.phn;
	keep phn r2rdate post_end servdate rx_enddate oat; 
run;

** b. Inclusion;
data c_oat04b;
    set c_oat04a;    
    /* 1. Define active prescription at discharge (allowing a 7-day grace window post-discharge) */
    if not missing(servdate) and not missing(rx_enddate) then do;
        if servdate <= (r2rdate + 7) and rx_enddate >= r2rdate then active_rx = 1;
        else active_rx = 0;
    end;
    else active_rx = 0;    
    /* Combine flags */
    if active_rx = 1 then inclusion = 1;
    else inclusion = 0;    
    /* Keep only eligible cohort */
    if inclusion = 1;
run;

** c. PNET records for included patients;
data c_oat04c; merge c_oat04b(in = a) b_pnet(in = b); by phn; if a = 1; run;

** d. Keep dispensation information;
data c_oat04d; set c_oat04c; keep phn servdate; run;

** e. Combine data;
data c_oat04e;
	merge c_oat04c
		  c_oat04d(firstobs=2 rename=(servdate=next_servdate phn=next_phn));
	if phn ne next_phn then next_servdate = .;
	if servdate < post_end;
	drop acpt: oat inclusion active_rx;
run;

* 5. Compute grace period;
data c_oat05;
	set c_oat04e;
	by phn;
	gap = next_servdate - rx_enddate;
	* Add a 3-day grace period;
	if gap = . or gap > 3 then stopdate = rx_enddate + 3;
	else if 1 <= gap <= 3 then stopdate = rx_enddate + gap;
	else stopdate = rx_enddate;
	format stopdate date9.;
run;

* 6. Define EOF;
data c_oat06;
	set c_oat05;
	if stopdate >= post_end then eof_date = post_end;
	else if gap = . or gap > 3 then eof_date = stopdate;
	else eof_date = post_end;
	if gap = . or gap > 3 then nograce_date = rx_enddate;
	else nograce_date = eof_date;
	format eof_date date9. nograce_date date9.;
run;

* 7. Extract last observations;
data c_oat07; set c_oat06; by phn; if last.phn; keep phn r2rdate post_end eof_date nograce_date; run;
data r2r.oat; 
	set c_oat07; 
	if post_end = eof_date then event_reg = 0; else event_reg = 1; 
	if post_end = nograce_date then event_nog = 0; else event_nog = 1; 
run;

/* Part D: Analysis */
* 1. Set up for IR calculation;
data d_oat01;
	set r2r.oat;
	f_days = floor(eof_date - r2rdate); 
	f_days_ng = floor(nograce_date - r2rdate);
	f_yr = f_days / 365.25;
	f_yr_ng = f_days_ng / 365.25;
	/* Set random seed for reproducibility */
    call streaminit(12345); 
    /* Assigns 1 with probability 0.5, and 0 otherwise */
    retention = rand("Bernoulli", 0.5);
run;

* 2. Sum up the number of events and person-years for each exposure category;
proc means data=d_oat01; var event_reg f_yr; class retention; output out=d_oat02a sum=event py; quit;
proc means data=d_oat01; var event_nog f_yr_ng; class retention; output out=d_oat02b sum=event py; quit;

* 3. Calculate incidence rate;
data d_oat03a;
	set d_oat02a;
	IR = event / (py/1000);
	LCI = quantile('chisq', 0.025, event*2) / ((py/1000)*2);
	UCI = quantile('chisq', 0.975, (event + 1)*2) / ((py/1000)*2);
run;
proc print data=d_oat03a; run;
data d_oat03b;
	set d_oat02b;
	IR = event / (py/1000);
	LCI = quantile('chisq', 0.025, event*2) / ((py/1000)*2);
	UCI = quantile('chisq', 0.975, (event + 1)*2) / ((py/1000)*2);
run;
proc print data=d_oat03b; run;

* 4. Cox PH model;
proc phreg data=d_oat01 fast;
	class retention (ref="0");
	model f_days*event_reg(0) = retention/risklimits alpha=0.05;
run;
proc phreg data=d_oat01 fast;
	class retention (ref="0");
	model f_days*event_nog(0) = retention/risklimits alpha=0.05;
run;

