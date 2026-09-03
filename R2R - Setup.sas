libname r2r "/home/u35232324/r2r";
proc datasets library=work kill nolist; quit;

/* Import Excel Files into SAS Format */
proc import datafile="/home/u35232324/r2r/dad.xlsx"
    out=r2r.dad         /* Name of the SAS dataset you want to create */
    dbms=xlsx                 /* Use 'xlsx' for .xlsx files or 'xls' for .xls files */
    replace;                  /* Overwrite the SAS dataset if it already exists */
    sheet="Sheet1";           /* Optional: Specify sheet name (defaults to first sheet) */
    getnames=YES;             /* Use the first row as SAS variable names */
run;

proc import datafile="/home/u35232324/r2r/deaths.xlsx"
    out=r2r.deaths         /* Name of the SAS dataset you want to create */
    dbms=xlsx                 /* Use 'xlsx' for .xlsx files or 'xls' for .xls files */
    replace;                  /* Overwrite the SAS dataset if it already exists */
    sheet="Sheet1";           /* Optional: Specify sheet name (defaults to first sheet) */
    getnames=YES;             /* Use the first row as SAS variable names */
run;

proc import datafile="/home/u35232324/r2r/deaths_icd.xlsx"
    out=r2r.deaths_icd         /* Name of the SAS dataset you want to create */
    dbms=xlsx                 /* Use 'xlsx' for .xlsx files or 'xls' for .xls files */
    replace;                  /* Overwrite the SAS dataset if it already exists */
    sheet="Sheet1";           /* Optional: Specify sheet name (defaults to first sheet) */
    getnames=YES;             /* Use the first row as SAS variable names */
run;

proc import datafile="/home/u35232324/r2r/df.xlsx"
    out=r2r.df         /* Name of the SAS dataset you want to create */
    dbms=xlsx                 /* Use 'xlsx' for .xlsx files or 'xls' for .xls files */
    replace;                  /* Overwrite the SAS dataset if it already exists */
    sheet="Sheet1";           /* Optional: Specify sheet name (defaults to first sheet) */
    getnames=YES;             /* Use the first row as SAS variable names */
run;

proc import datafile="/home/u35232324/r2r/msp.xlsx"
    out=r2r.msp         /* Name of the SAS dataset you want to create */
    dbms=xlsx                 /* Use 'xlsx' for .xlsx files or 'xls' for .xls files */
    replace;                  /* Overwrite the SAS dataset if it already exists */
    sheet="Sheet1";           /* Optional: Specify sheet name (defaults to first sheet) */
    getnames=YES;             /* Use the first row as SAS variable names */
run;

proc import datafile="/home/u35232324/r2r/nacrs.xlsx"
    out=r2r.nacrs         /* Name of the SAS dataset you want to create */
    dbms=xlsx                 /* Use 'xlsx' for .xlsx files or 'xls' for .xls files */
    replace;                  /* Overwrite the SAS dataset if it already exists */
    sheet="Sheet1";           /* Optional: Specify sheet name (defaults to first sheet) */
    getnames=YES;             /* Use the first row as SAS variable names */
run;

proc import datafile="/home/u35232324/r2r/pnet.xlsx"
    out=r2r.pnet         /* Name of the SAS dataset you want to create */
    dbms=xlsx                 /* Use 'xlsx' for .xlsx files or 'xls' for .xls files */
    replace;                  /* Overwrite the SAS dataset if it already exists */
    sheet="Sheet1";           /* Optional: Specify sheet name (defaults to first sheet) */
    getnames=YES;             /* Use the first row as SAS variable names */
run;

/** Part A: Cohort Construction **/
* 1. Identify date of SUD;
** a. DAD;
data a_data01a;
    set r2r.dad;
    /* 1. Define an array for the 25 diagnosis variables */
    array diag[25] $ diagx1 - diagx25;
    /* 2. Flag variable for finding a match on the current row */
    length sud 8;
    sud = 0;
    /* 3. Loop through diagnosis columns 1 to 25 */
    do i = 1 to 25;
        /* Using UPCASE and STRIP prevents issues with lowercase letters or leading spaces */
        if upcase(strip(diag[i])) in: ('F10', 'F11', 'F12', 'F13', 'F14', 
        	'F15', 'F16', 'F17', 'F18', 'F19', 'K70', 'T51', 'T40',
        	'T43', 'T44', 'T45', 'T46', 'T47', 'T48', 'T49', 'T50',
        	'X40', 'X41', 'X42', 'X43', 'X44', 'X45',
        	'X60', 'X61', 'X62', 'X63', 'X64', 'X65',
        	'Y10', 'Y11', 'Y12', 'Y13', 'Y14', 'Y15') then do;
            sud = 1;
            leave; /* Stop checking remaining columns for this row once found */
        end;
    end;
    /* Drop temporary loop index */
    drop i;
    /* Keep only records where an SUD diagnosis was present */
    if sud = 1;
run;

** b. NACRS;
data a_data01b;
    set r2r.nacrs;
    /* 1. Define an array for the 3 diagnosis variables */
    array diag[3] $ eddiag1 - eddiag3;
    /* 2. Flag variable for finding a match on the current row */
    length sud 8;
    sud = 0;
    /* 3. Loop through diagnosis columns 1 to 3 */
    do i = 1 to 3;
        /* Using UPCASE and STRIP prevents issues with lowercase letters or leading spaces */
        if upcase(strip(diag[i])) in: ('F10', 'F11', 'F12', 'F13', 'F14', 
        	'F15', 'F16', 'F17', 'F18', 'F19', 'K70', 'T51', 'T40',
        	'T43', 'T44', 'T45', 'T46', 'T47', 'T48', 'T49', 'T50',
        	'X40', 'X41', 'X42', 'X43', 'X44', 'X45',
        	'X60', 'X61', 'X62', 'X63', 'X64', 'X65',
        	'Y10', 'Y11', 'Y12', 'Y13', 'Y14', 'Y15') then do;
            sud = 1;
            leave; /* Stop checking remaining columns for this row once found */
        end;
    end;
    /* Drop temporary loop index */
    drop i;
    /* Keep only records where an SUD diagnosis was present */
    if sud = 1;
run;

** c. MSP;
data a_data01c; 
	set r2r.msp; 
	rename phnnum = phn clntgndr = gender diagcd = diagcd1 clntbrdt = dob toservdt = servdate; 
run;

data a_data01c;
    set a_data01c;
    /* 1. Define an array for the 3 diagnosis variables */
    array diag[3] $ diagcd1 - diagcd3;
    /* 2. Flag variable for finding a match on the current row */
    length sud 8;
    sud = 0;
    /* 3. Loop through diagnosis columns 1 to 3 */
    do i = 1 to 3;
        /* Using UPCASE and STRIP prevents issues with lowercase letters or leading spaces */
        if upcase(strip(diag[i])) in: 
        	('F10', 'F11', 'F12', 'F13', 'F14', 'F15', 'F16', 'F17', 'F18', 'F19',
        	'291', '303', '3050', '3040', '3047', '3055', '3043', '3052', 
        	'3041', '3054', '3042', '3044', '3056', '3057', '3045', '3053', '3051') 
        	then do;
            sud = 1;
            leave; /* Stop checking remaining columns for this row once found */
        end;
    end;
    /* Drop temporary loop index */
    drop i;
    /* Keep only records where an SUD diagnosis was present */
    if sud = 1;
run;

*** 1. Operationalize 2 physician visits in 1 year;
proc sort data=a_data01c; by phn servdate; run;
data a_data01c1; set a_data01c; by phn; if first.phn then count = 0; count + 1; run;
*** 2. Identify date of first SUD diagnosis;
proc sql;
	create table a_data01c2 as
	select *, min(servdate) as initdx format=date9., max(count) as totaldxnum
	from a_data01c1
	group by phn
	order by phn, servdate, count;
quit;
*** 3. Keep only those with multiple diagnoses;
data a_data01c3; set a_data01c2; by phn; if totaldxnum >= 2; run;
*** 4. Calculate the gap between any two SUD events;
data a_data01c4;
	set a_data01c3;
	by phn;
	lag_sud_date = lag(servdate);
	format lag_sud_date date9.;
	gap = servdate - lag_sud_date;
	if first.phn then do;
		lag_sud_date = .;
		gap = .;
		sud1yr = .;
	end;
	* 2 physician visits in 1 year;
	if gap ne . and gap <= 365 then sud1yr = 1;
	else if gap > 365 then sud1yr = 0;
run;
*** 5. Ascertain outcome;
data a_data01c5; set a_data01c4; by phn; if sud1yr = 1; run;
*** 6. Calculate the earliest date of 2P1Y;
proc sql;
	create table a_data01c6 as
	select *, min(lag_sud_date) as case1yr format=date9.
	from a_data01c5
	group by phn
	order by phn, lag_sud_date, count;
quit;
*** 7. Remove duplicates;
proc sort data=a_data01c6 out=a_data01c7 nodupkey; by phn; run;

** d. PNET;
data a_data01d; set r2r.pnet; rename clnt_key = phn srv_date = servdate; run;
data a_data01d;
	set a_data01d;
	length oat 8 oat_type $ 30;
    oat = 0;
    oat_type = "Non-OAT";
    
    /* 1. Methadone Maintenance (PINs) */
    if din_pin in (
    	999792, 999793, 66999990, 66999991, 66999992, 66999993,
        66999997, 66999998, 66999999, 67000000,
        67000001, 67000002, 67000003, 67000004,
        67000005, 67000006, 67000007, 67000008,
        67000013, 67000014, 67000015, 67000016, 2394596, 2244290
    ) then do;
        oat = 1;
        oat_type = "Methadone";
    end;
    
    /* 2. Buprenorphine / Naloxone (Suboxone & Generics) */
    /* Note: Leading zeros dropped (e.g., 02453908 -> 2453908) */
    else if din_pin in (
        2295695, 2295709, 2408090, 2408104, 2424851, 2424878,
        2453908, 2453916, 2468085, 2468093, 2502321, 2502348,
        2502356, 2517175,
        2242962, 2242963, 2242964, 66999994, 66999995, 66999996, 2483084, 2483092
    ) then do;
        oat = 1;
        oat_type = "Buprenorphine/Naloxone";
    end;
    
    /* 3. Sublocade (Injectable Buprenorphine) */
    else if din_pin in (
        66123367, 2146126, 22123340, 22123357
    ) then do;
        oat = 1;
        oat_type = "Sublocade";
    end;
    
    /* 4. Kadian (SROM for OAT) */
    else if din_pin in (
        22123349, 22123346, 22123347, 22123348, 22123405
    ) then do;
        oat = 1;
        oat_type = "Kadian (SROM)";
    end;
    
    /* 5. Transaction Medication Updates (Clinic Admin/Stock) */
    else if din_pin in (
        66128342, 66128343, 66128344, 66128345, 66128346
    ) then do;
        oat = 1;
        oat_type = "OAT Clinical Admin";
    end;
    if oat = 1;
run;

** e. Sort data by PHN;
proc sort data=a_data01a; by phn addate; run;
proc sort data=a_data01b; by phn regdate; run;
proc sort data=a_data01c7; by phn case1yr; run;
proc sort data=a_data01d; by phn servdate; run;

* 2. Harmonize files for concatenation;
data a_data02a; set a_data01a; rename addate = suddate; keep phn addate; run;
data a_data02b; set a_data01b; rename regdate = suddate; keep phn regdate; run;
data a_data02c; set a_data01c7; rename case1yr = suddate; keep phn case1yr; run;
data a_data02d; set a_data01d; rename servdate = suddate; keep phn servdate; run;
data a_data02; set a_data02a a_data02b a_data02c a_data02d; format suddate date9.; run;
proc sort data=a_data02; by phn suddate; run;

* 3. Remove duplicates;
proc sort data=a_data02 out=a_data03 nodupkey; by phn; run;

* 4. Gather R2R info;
data a_data04; 
	set r2r.df;
	if indigenous_identity in ("Non-Indigenous", "zzOutside of Canada") then indigenous = 0;
	else indigenous = 1;
	rename bc_phn = phn date_of_r2r_admission = r2rdate;
	if in_study_period = 1;
	keep bc_phn indigenous date_of_r2r_admission; 
run;
proc sort data=a_data04; by phn; run;

* 5. Left join SUD patients and R2R;
data a_data05;
	merge a_data03(in = x) a_data04(in = y) a_data01a(in = z keep = dob gender phn);
	by phn;
	if x = 1;
	* Limit to those who did not use R2R and had SUD at R2R initiation;
	if r2rdate = . or (suddate < r2rdate);
	* Compute SUD duration;
	* if r2rdate = . then sud_duration = .;
	* else sud_duration = r2rdate - suddate;
	* Derive demographic variables;
	if gender = "M" then male = 1; else male = 0;
	* if r2rdate = . then age_index = .;
	* else age_index = floor((r2rdate - dob)/365.25);
	if r2rdate = . then r2r = 0; else r2r = 1;
	format r2rdate date09. dob date09.;
	* Limit to those with DOB;
	if dob ne .;
	drop gender;
run;

* 6. Add death date;
data a_death; 
	set r2r.deaths; 
	rename deceased_hi_identifier = phn date_of_death = deathdate;
	keep deceased_hi_identifier date_of_death;
	format date_of_death date9.;
run;
proc sort data=a_death; by phn; run;
data a_data06; merge a_data05(in = x) a_death(in = y); by phn; if x = 1; run;
data r2r.sud; set a_data06; run;

/** Part B: Data Setup **/
* 0. Create R2R and control datasets;
data b_data00r; set a_data06; r2rdate = floor(r2rdate); if r2r = 1; run;
data b_data00c; set a_data06; r2rdate = floor(r2rdate); if r2r = 0; run;

/********************************************************************************
 PHASE 1: ASSIGN PSEUDO-INDEX DATES & CONSTRUCT RISK-SET CANDIDATES
 ********************************************************************************/
/* Define study block start and end (Format: YYYYMM) */
%let start_block = 202209;
%let end_block   = 202512;

/* ------------------------------------------------------------------------------
   Step 1: Format Treated Group with Actual Index Date
   ------------------------------------------------------------------------------ */
data treated_candidates;
    set b_data00r;
    /* Ensure block is numeric YYYYMM */
    if r2rdate ne . then block = year(r2rdate) * 100 + month(r2rdate);
    /* Keep within study window */
    treated    = 1;
    index_date = r2rdate;
    format index_date date9.;
    /* Subsetting IF (Evaluates AFTER block is calculated) */
    if block >= &start_block and block <= &end_block;
run;

/* ------------------------------------------------------------------------------
   Step 2: Generate Control Candidates across Monthly Blocks via Macro Loop
   ------------------------------------------------------------------------------ */
proc datasets lib=work nolist; delete control_candidates_all; quit;
%macro generate_control_risk_sets;
    %let current_b = &start_block;
    %do %while (&current_b <= &end_block);        
        /* A. Extract Year and Month from current block */
        %let yr = %sysfunc(floor(&current_b / 100));
        %let mo = %sysfunc(mod(&current_b, 100));        
        /* B. Assign Mid-Month Pseudo-Index Date (e.g., 15th of the block month) */
        %let block_pseudo_date = %sysfunc(mdy(&mo, 15, &yr));
        /* C. Filter eligible controls for current block & assign pseudo-index date */
        data control_block_&current_b;
            set b_data00c;            
            /* 1. Exclude individuals who accessed R2R prior to or during this block */
            if r2rdate ne . and r2rdate <= intnx('month', &block_pseudo_date, 0, 'end') then delete;            
            /* 2. Exclude individuals deceased prior to this block pseudo-index date */
            *if death_date ne . and deathdate < &block_pseudo_date then delete;
            /* Assign Candidate Dates and Identifiers */
            treated           = 0;
            block             = &current_b;
            pseudo_index_date = &block_pseudo_date;
            index_date        = pseudo_index_date;            
            format pseudo_index_date index_date date9.;
        run;
        /* D. Append to master control candidates table */
        proc append base=control_candidates_all data=control_block_&current_b force; run;        
        /* Clean up temporary block table */
        proc delete data=control_block_&current_b; run;
        /* E. Increment to next calendar month block (YYYYMM logic) */
        data _null_;
            cb = &current_b;
            y  = floor(cb / 100);
            m  = mod(cb, 100);
            if m = 12 then next_cb = (y + 1) * 100 + 1;
            else next_cb = cb + 1;
            call symputx('current_b', next_cb);
        run;
    %end;
%mend generate_control_risk_sets;
%generate_control_risk_sets;

/* ------------------------------------------------------------------------------
   Step 3: Combine Treated & Control Candidates into Single Master Output Table
   ------------------------------------------------------------------------------ */
data master_candidate_pool; set treated_candidates control_candidates_all; run;
proc sort data=master_candidate_pool; by phn; run;

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
data b_df; set a_data04; keep phn r2rdate; run;
proc sort data=b_msp; by phn servdate; run;
proc sort data=b_nacrs; by phn regdate; run;
proc sort data=b_dad; by phn addate; run;
proc sort data=b_pnet; by phn servdate; run;
proc sort data=b_df; by phn; run;

/* Part C: Covariates */
/** Subpart 1: Health Service Use **/
* 1. Organize health records;
data c_data01a; merge b_msp(in = x) b_df(in = y); by phn; if x = 1; run;
data c_data01b; merge b_nacrs(in = x) b_df(in = y); by phn; if x = 1; run;
data c_data01c; merge b_dad(in = x) b_df(in = y); by phn; if x = 1; run;
data c_data01d; merge b_pnet(in = x) b_df(in = y); by phn; if x = 1; run;

* 2. Merge data;
** a. Physician visits;
proc sql;
	create table c_data02a as
	select 
		a.phn, a.r2r, a.treated, a.block, a.index_date, a.pseudo_index_date,
		/* 1. Unify the reference index date based on r2r status */
		coalesce(a.index_date, a.pseudo_index_date) as ref_index_date format=DATE9.,
		/* 2. Service data attributes */
		b.servdate, b.diagcd1, b.diagcd2, b.diagcd3,
		/* 3. Flag if service date is within the 1-year prior window */
		case 
			when b.servdate is not missing 
                 and (calculated ref_index_date - 365 <= b.servdate < calculated ref_index_date) 
            then 1
			else 0
		end as serv_1yr_flag
	from master_candidate_pool as a
	left join c_data01a as b on a.phn = b.phn
	order by a.phn, ref_index_date, b.servdate;
quit;

** b. ED visits;
proc sql;
	create table c_data02b as
	select 
		a.phn, a.r2r, a.treated, a.block, a.index_date, a.pseudo_index_date,
		/* 1. Unify the reference index date based on r2r status */
		coalesce(a.index_date, a.pseudo_index_date) as ref_index_date format=DATE9.,
		/* 2. Service data attributes */
		b.regdate, b.eddiag1, b.eddiag2, b.eddiag3,
		/* 3. Flag if service date is within the 1-year prior window */
		case 
			when b.regdate is not missing 
                 and (calculated ref_index_date - 365 <= b.regdate < calculated ref_index_date) 
            then 1
			else 0
		end as serv_1yr_flag
	from master_candidate_pool as a
	left join c_data01b as b on a.phn = b.phn
	order by a.phn, ref_index_date, b.regdate;
quit;

** c. Hospitalizations;
proc sql;
	create table c_data02c as
	select 
		a.phn, a.r2r, a.treated, a.block, a.index_date, a.pseudo_index_date,
		/* 1. Unify the reference index date based on r2r status */
		coalesce(a.index_date, a.pseudo_index_date) as ref_index_date format=DATE9.,
		/* 2. Service data attributes */
		b.addate, b.diagx1, b.diagx2, b.diagx3, b.diagx4, b.diagx5, b.diagx6,
		b.diagx7, b.diagx8, b.diagx9, b.diagx10, b.diagx11, b.diagx12,
		b.diagx13, b.diagx14, b.diagx15, b.diagx16, b.diagx17, b.diagx18,
		b.diagx19, b.diagx20, b.diagx21, b.diagx22, b.diagx23, b.diagx24,
		b.diagx25,
		/* 3. Flag if service date is within the 1-year prior window */
		case 
			when b.addate is not missing 
                 and (calculated ref_index_date - 365 <= b.addate < calculated ref_index_date) 
            then 1
			else 0
		end as serv_1yr_flag
	from master_candidate_pool as a
	left join c_data01c as b on a.phn = b.phn
	order by a.phn, ref_index_date, b.addate;
quit;

* 3. Compute health service use;
** a. Physician visits;
proc sql;
	create table c_data03a as
	select 
		phn, r2r, treated, block, ref_index_date as index_date,
		/* Total number of service encounters in 1-year prior window */
		sum(serv_1yr_flag) as op_num_1yr,
		/* Binary flag: 1 if at least one service encounter in prior year, 0 otherwise */
		max(serv_1yr_flag) as op_any_1yr
	from c_data02a
	group by phn, r2r, treated, block, index_date;
quit;

** b. ED visits;
proc sql;
	create table c_data03b as
	select 
		phn, r2r, treated, block, ref_index_date as index_date,
		/* Total number of service encounters in 1-year prior window */
		sum(serv_1yr_flag) as ed_num_1yr,
		/* Binary flag: 1 if at least one service encounter in prior year, 0 otherwise */
		max(serv_1yr_flag) as ed_any_1yr
	from c_data02b
	group by phn, r2r, treated, block, index_date;
quit;

** c. Hospitalizations;
proc sql;
	create table c_data03c as
	select 
		phn, r2r, treated, block, ref_index_date as index_date,
		/* Total number of service encounters in 1-year prior window */
		sum(serv_1yr_flag) as hp_num_1yr,
		/* Binary flag: 1 if at least one service encounter in prior year, 0 otherwise */
		max(serv_1yr_flag) as hp_any_1yr
	from c_data02c
	group by phn, r2r, treated, block, index_date;
quit;

* 4. Combine HSR data;
proc sort data=c_data03a nodupkey; by phn index_date; run;
proc sort data=c_data03b nodupkey; by phn index_date; run;
proc sort data=c_data03c nodupkey; by phn index_date; run;
data c_data04;
	merge master_candidate_pool(in = x) 
		c_data03a(in = a keep = phn index_date op_num_1yr op_any_1yr)
		c_data03b(in = b keep = phn index_date ed_num_1yr ed_any_1yr)
		c_data03c(in = c keep = phn index_date hp_num_1yr hp_any_1yr);
	by phn index_date;
	if x = 1;
	age_yr_index = floor((index_date - dob)/365.25);
	sud_yr_dur = (index_date - suddate)/365.25;
	if index_date - suddate >= 0;
run;
proc freq data=c_data04; table op: ed: hp:; run;

/** Subpart 2: Overdose Events **/
* 5. Identify OD events;
** a. MSP;
data c_data05a;
    set c_data01a;
    /* 1. Define an array for the 3 diagnosis variables */
    array diag[3] $ diagcd1 - diagcd3;
    /* 2. Flag variable for finding a match on the current row */
    length od 8;
    od = 0;
    /* 3. Loop through diagnosis columns 1 to 3 */
    do i = 1 to 3;
        /* Using UPCASE and STRIP prevents issues with lowercase letters or leading spaces */
        if upcase(strip(diag[i])) in: 
        	('T400','T401','T402', 'T403', 'T404', 'T406',
			 '9650', 'E8500', 'E8501', 'E8502',
        	 'T405', 'T407', 'T408', 'T409', 'T423', 'T424', 'T426', 
        	 'T427', 'T436', 'T438', 'T439', 'T449', 'T51',
			 '9670', '9678', '9679', '9685', '9694', '9696', '9698', '9699',
			 '9700', '97081', '97089', '9719', '980',
			 'E8532', 'E854', 'E860') 
        	then do;
            od = 1;
            leave; /* Stop checking remaining columns for this row once found */
        end;
    end;
    /* Drop temporary loop index */
    drop i;
run;

** b. NACRS;
data c_data05b;
    set c_data01b;
    /* 1. Define an array for the 3 diagnosis variables */
    array diag[3] $ eddiag1 - eddiag3;
    /* 2. Flag variable for finding a match on the current row */
    length od 8;
    od = 0;
    /* 3. Loop through diagnosis columns 1 to 3 */
    do i = 1 to 3;
        /* Using UPCASE and STRIP prevents issues with lowercase letters or leading spaces */
        if upcase(strip(diag[i])) in: (
        	 'T400','T401','T402', 'T403', 'T404', 'T406',
			 '9650', 'E8500', 'E8501', 'E8502',
        	 'T405', 'T407', 'T408', 'T409', 'T423', 'T424', 'T426', 
        	 'T427', 'T436', 'T438', 'T439', 'T449', 'T51',
			 '9670', '9678', '9679', '9685', '9694', '9696', '9698', '9699',
			 '9700', '97081', '97089', '9719', '980',
			 'E8532', 'E854', 'E860') then do;
            od = 1;
            leave; /* Stop checking remaining columns for this row once found */
        end;
    end;
    /* Drop temporary loop index */
    drop i;
run;

** c. DAD;
data c_data05c;
    set c_data01c;
    /* 1. Define an array for the 25 diagnosis variables */
    array diag[25] $ diagx1 - diagx25;
    /* 2. Flag variable for finding a match on the current row */
    length od 8;
    od = 0;
    /* 3. Loop through diagnosis columns 1 to 25 */
    do i = 1 to 25;
        /* Using UPCASE and STRIP prevents issues with lowercase letters or leading spaces */
        if upcase(strip(diag[i])) in: (
        	 'T400','T401','T402', 'T403', 'T404', 'T406',
			 '9650', 'E8500', 'E8501', 'E8502',
        	 'T405', 'T407', 'T408', 'T409', 'T423', 'T424', 'T426', 
        	 'T427', 'T436', 'T438', 'T439', 'T449', 'T51',
			 '9670', '9678', '9679', '9685', '9694', '9696', '9698', '9699',
			 '9700', '97081', '97089', '9719', '980',
			 'E8532', 'E854', 'E860') then do;
            od = 1;
            leave; /* Stop checking remaining columns for this row once found */
        end;
    end;
    /* Drop temporary loop index */
    drop i;
run;

* 6. Merge data;
** a. Physician visits;
proc sql;
	create table c_data06a as
	select 
		a.phn, a.r2r, a.treated, a.block, a.index_date, a.pseudo_index_date,
		/* 1. Unify the reference index date based on r2r status */
		coalesce(a.index_date, a.pseudo_index_date) as ref_index_date format=DATE9.,
		/* 2. Service data attributes */
		b.servdate, b.diagcd1, b.diagcd2, b.diagcd3, b.od,
		/* 3. Flag if service date is within the 1-year prior window */
		case 
			when b.servdate is not missing and b.od = 1
                 and (calculated ref_index_date - 14 <= b.servdate < calculated ref_index_date) 
            then 1
			else 0
		end as serv_2wk_flag
	from master_candidate_pool as a
	left join c_data05a as b on a.phn = b.phn
	order by a.phn, ref_index_date, b.servdate;
quit;

** b. ED visits;
proc sql;
	create table c_data06b as
	select 
		a.phn, a.r2r, a.treated, a.block, a.index_date, a.pseudo_index_date,
		/* 1. Unify the reference index date based on r2r status */
		coalesce(a.index_date, a.pseudo_index_date) as ref_index_date format=DATE9.,
		/* 2. Service data attributes */
		b.regdate, b.eddiag1, b.eddiag2, b.eddiag3, b.od,
		/* 3. Flag if service date is within the 1-year prior window */
		case 
			when b.regdate is not missing and b.od = 1
                 and (calculated ref_index_date - 14 <= b.regdate < calculated ref_index_date) 
            then 1
			else 0
		end as serv_2wk_flag
	from master_candidate_pool as a
	left join c_data05b as b on a.phn = b.phn
	order by a.phn, ref_index_date, b.regdate;
quit;

** c. Hospitalizations;
proc sql;
	create table c_data06c as
	select 
		a.phn, a.r2r, a.treated, a.block, a.index_date, a.pseudo_index_date,
		/* 1. Unify the reference index date based on r2r status */
		coalesce(a.index_date, a.pseudo_index_date) as ref_index_date format=DATE9.,
		/* 2. Service data attributes */
		b.addate, b.diagx1, b.diagx2, b.diagx3, b.diagx4, b.diagx5, b.diagx6,
		b.diagx7, b.diagx8, b.diagx9, b.diagx10, b.diagx11, b.diagx12,
		b.diagx13, b.diagx14, b.diagx15, b.diagx16, b.diagx17, b.diagx18,
		b.diagx19, b.diagx20, b.diagx21, b.diagx22, b.diagx23, b.diagx24,
		b.diagx25, b.od,
		/* 3. Flag if service date is within the 1-year prior window */
		case 
			when b.addate is not missing and b.od = 1
                 and (calculated ref_index_date - 14 <= b.addate < calculated ref_index_date) 
            then 1
			else 0
		end as serv_2wk_flag
	from master_candidate_pool as a
	left join c_data05c as b on a.phn = b.phn
	order by a.phn, ref_index_date, b.addate;
quit;

* 7. Identify OD in 1 year block;
** a. Physician visits;
proc sql;
	create table c_data07a as
	select 
		phn, r2r, treated, block, ref_index_date as index_date,
		/* Binary flag: 1 if at least one service encounter in prior year, 0 otherwise */
		max(serv_2wk_flag) as op_od_2wk
	from c_data06a
	group by phn, r2r, treated, block, index_date;
quit;

** b. ED visits;
proc sql;
	create table c_data07b as
	select 
		phn, r2r, treated, block, ref_index_date as index_date,
		/* Binary flag: 1 if at least one service encounter in prior year, 0 otherwise */
		max(serv_2wk_flag) as ed_od_2wk
	from c_data06b
	group by phn, r2r, treated, block, index_date;
quit;

** c. Hospitalizations;
proc sql;
	create table c_data07c as
	select 
		phn, r2r, treated, block, ref_index_date as index_date,
		/* Binary flag: 1 if at least one service encounter in prior year, 0 otherwise */
		max(serv_2wk_flag) as hp_od_2wk
	from c_data06c
	group by phn, r2r, treated, block, index_date;
quit;

* 8. Combine OD data;
proc sort data=c_data07a nodupkey; by phn index_date; run;
proc sort data=c_data07b nodupkey; by phn index_date; run;
proc sort data=c_data07c nodupkey; by phn index_date; run;
data c_data08;
	merge c_data04(in = x) 
		c_data07a(in = a keep = phn index_date op_od_2wk)
		c_data07b(in = b keep = phn index_date ed_od_2wk)
		c_data07c(in = c keep = phn index_date hp_od_2wk);
	by phn index_date;
	if x = 1;
	if sum(op_od_2wk, ed_od_2wk, hp_od_2wk) >= 1 then overdose = 1;
	else overdose = 0;
	drop op_od: ed_od: hp_od:;
run;
proc freq data=c_data08; table overdose; run;

/** Subpart 3: OAT Use **/
* 9. Identify OAT;
data c_data09;
	set c_data01d;
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
run;
** a. Create lag dates;
data c_data09a; set c_data09; keep phn servdate; run;
data c_data09b;
	merge c_data09
		  c_data09a(firstobs=2 rename=(servdate=next_servdate phn=next_phn));
	if phn ne next_phn then next_servdate = .;
run;

* 10. OAT discontinuation 14 days before index;
proc sql;
	create table c_data10 as
	select 
		a.phn, a.r2r, a.treated, a.block, a.index_date, a.pseudo_index_date,
		/* 1. Unify the reference index date based on r2r status */
		coalesce(a.index_date, a.pseudo_index_date) as ref_index_date format=DATE9.,
		/* 2. Service data attributes */
		b.servdate, b.din_pin, b.rx_enddate, b.next_servdate, b.oat,
		/* 3. Flag if service date is within the 14-day prior window */
		case 
			when b.servdate is not missing and b.oat = 1
                 and (calculated ref_index_date - 14 <= b.rx_enddate < calculated ref_index_date)
                 /* Gap Condition: Next service is >14 days after rx_enddate OR missing (no refill) */
                 and ( (b.next_servdate - b.rx_enddate > 14) or missing(b.next_servdate) )
            then 1
			else 0
		end as oat2wk
	from master_candidate_pool as a
	left join c_data09b as b on a.phn = b.phn
	order by a.phn, ref_index_date, b.servdate;
quit;

* 11. Identify OAT use in 2 week block;
proc sql;
	create table c_data11 as
	select 
		phn, r2r, treated, block, ref_index_date as index_date,
		/* Binary flag: 1 if at least one discontinuation in prior 14 days */
		max(oat2wk) as oat_disc_2wk
	from c_data10
	group by phn, r2r, treated, block, index_date;
quit;
proc freq data=c_data11; table oat_disc_2wk; run;

* 12. Combine data;
proc sort data=c_data08 nodupkey; by phn block index_date; run;
proc sort data=c_data11 nodupkey; by phn block index_date; run;
data c_data12;
	merge c_data08(in = x) c_data11(in = a keep = phn block index_date oat_disc_2wk);
	by phn block index_date;
	if x = 1;
	if missing(oat_disc_2wk) then oat_disc_2wk = 0;
run;
proc freq data=c_data12; table overdose oat_disc_2wk; run;

/** Subpart 4: Charlson Comorbidity Index **/
* 13. Hospitalization in 1 year period;
proc sql;
	create table c_data13 as
	select 
		a.phn, a.r2r, a.treated, a.block, a.index_date, a.pseudo_index_date,
		/* 1. Unify the reference index date based on r2r status */
		coalesce(a.index_date, a.pseudo_index_date) as ref_index_date format=DATE9.,
		/* 2. Service data attributes */
		b.addate, b.diagx1, b.diagx2, b.diagx3, b.diagx4, b.diagx5, b.diagx6,
		b.diagx7, b.diagx8, b.diagx9, b.diagx10, b.diagx11, b.diagx12,
		b.diagx13, b.diagx14, b.diagx15, b.diagx16, b.diagx17, b.diagx18,
		b.diagx19, b.diagx20, b.diagx21, b.diagx22, b.diagx23, b.diagx24,
		b.diagx25,
		/* 3. Flag if service date is within the 1-year prior window */
		case 
			when b.addate is not missing
                 and (calculated ref_index_date - 365 <= b.addate < calculated ref_index_date) 
            then 1
			else 0
		end as hosp1yr
	from master_candidate_pool as a
	left join c_data01c as b on a.phn = b.phn
	order by a.phn, ref_index_date, b.addate;
quit;

* 14. Compute CCI;
%macro _CharlsonICD10 (DATA    =,                  /* input data set */
                       OUT     =,                  /* output data set */
                       dx      = diagx1-diagx25,   /* range of diagnosis variables */
                       addate  =,           /* admission/service date variable */
                       refdate =,   /* reference index date variable */
                       debug   = off );

	%let debug = %lowcase(&debug) ;
	/* put default options into &opts variable */
	%let opts = %sysfunc(getoption(mprint,)) %sysfunc(getoption(notes,)) ;
	%if &debug=1 | &debug=debug %then %do ;
		options mprint notes ;
	%end ;
	%else %do ;
		options nomprint nonotes ;
	%end ;
	
	/* Check if previous step had an error */
	%if %eval(&SYSERR>0) %then %goto out1 ;   
	/* Check if input data exists */
	%if &data= %str() %then %goto out2 ;  
	/* If output dataset not defined, set it equal to input */
	%if &out= %then %let out=&data ;  
	%if %index(&data,.) %then %do;
		%let libname=%scan(&data,1);
		%let data=%scan(&data,2);
	%end;
	%else %do ;
		%let libname=work ;
		%let data=&data ;
	%end ;
	%if %sysfunc(exist(&libname..&data)) ^= 1 %then %goto out3 ;	

	data &OUT;
		set &libname..&DATA ;
		/* Set up array for individual CCI group counters */
		array CC_GRP (17) CC_GRP_1 - CC_GRP_17;
		/* Set up array for diagnosis codes within a record */
		array DX (*) &dx;
		
		/* Initialize all CCI group counters to zero */
		do i = 1 to 17;
			CC_GRP(i) = 0;
		end;

		/* ---------------------------------------------------------------------
		   Check if admission date falls within the 1-year prior lookback window:
		   [ref_index_date - 365 <= addate < ref_index_date]
		   --------------------------------------------------------------------- */
		if &addate ne . and &refdate ne . then do;
			if (&refdate - 365 <= &addate < &refdate) then do;

				/* Check each diagnosis code in the record */
				do i = 1 to dim(dx) UNTIL (DX(i)=' ');
					
					/* Myocardial Infarction */
					if DX(i) IN: ('I21', 'I22','I252') then CC_GRP_1 = 1;
					LABEL CC_GRP_1 = 'Myocardial Infarction';
					
					/* Congestive Heart Failure */
					if DX(i) IN: ('I43','I50','I099','I110','I130','I132','I255','I420','I425','I426',
					              'I427','I428','I429','P290') then CC_GRP_2 = 1;
					LABEL CC_GRP_2 = 'Congestive Heart Failure';
					
					/* Peripheral Vascular Disease */
					if DX(i) IN: ('I70','I71','I731','I738','I739','I771','I790','I792','K551','K558',
					              'K559','Z958','Z959') then CC_GRP_3 = 1;
					LABEL CC_GRP_3 = 'Peripheral Vascular Disease';
					
					/* Cerebrovascular Disease */
					if DX(i) IN: ('G45','G46','I60','I61','I62','I63','I64','I65','I66','I67','I68',
					              'I69','H340') then CC_GRP_4 = 1;
					LABEL CC_GRP_4 = 'Cerebrovascular Disease';
					
					/* Dementia */
					if DX(i) IN: ('F00','F01','F02','F03','G30','F051','G311') then CC_GRP_5 = 1;
					LABEL CC_GRP_5 = 'Dementia';
					
					/* Chronic Pulmonary Disease */
					if DX(i) IN: ('J40','J41','J42','J43','J44','J45','J46','J47','J60','J61','J62','J63',
					              'J64','J65','J66','J67','I278','I279','J684','J701','J703') then CC_GRP_6 = 1;
					LABEL CC_GRP_6 = 'Chronic Pulmonary Disease';
					
					/* Connective Tissue Disease-Rheumatic Disease */
					if DX(i) IN: ('M05','M32','M33','M34','M06','M315','M351','M353','M360') then CC_GRP_7 = 1;
					LABEL CC_GRP_7 = 'Connective Tissue Disease-Rheumatic Disease';
					
					/* Peptic Ulcer Disease */
					if DX(i) IN: ('K25','K26','K27','K28') then CC_GRP_8 = 1;
					LABEL CC_GRP_8 = 'Peptic Ulcer Disease';
					
					/* Mild Liver Disease */
					if DX(i) IN: ('B18','K73','K74','K700','K701','K702','K703','K709','K717','K713',
					              'K714','K715','K760','K762','K763','K764','K768','K769','Z944') then CC_GRP_9 = 1;
					LABEL CC_GRP_9 = 'Mild Liver Disease';
					
					/* Diabetes without complications */
					if DX(i) IN: ('E100','E101','E106','E108','E109','E110','E111','E116','E118','E119',
					              'E120','E121','E126','E128','E129','E130','E131','E136','E138','E139',
					              'E140','E141','E146','E148','E149') then CC_GRP_10 = 1;
					LABEL CC_GRP_10 = 'Diabetes without complications';
					
					/* Diabetes with complications */
					if DX(i) IN: ('E102','E103','E104','E105','E107','E112','E113','E114','E115','E117',
					              'E122','E123','E124','E125','E127','E132','E133','E134','E135','E137',
					              'E142','E143','E144','E145','E147') then CC_GRP_11 = 1;
					LABEL CC_GRP_11 = 'Diabetes with complications';
					
					/* Paraplegia and Hemiplegia */
					if DX(i) IN: ('G81','G82','G041','G114','G801','G802','G830','G831','G832','G833',
					              'G834','G839') then CC_GRP_12 = 1;
					LABEL CC_GRP_12 = 'Paraplegia and Hemiplegia';
					
					/* Renal Disease */
					if DX(i) IN: ('N18','N19','N052','N053','N054','N055','N056','N057','N250','I120',
					              'I131','N032','N033','N034','N035','N036','N037','Z490','Z491','Z492',
					              'Z940','Z992') then CC_GRP_13 = 1;
					LABEL CC_GRP_13 = 'Renal Disease';
					
					/* Cancer */
					if DX(i) IN: ('C00','C01','C02','C03','C04','C05','C06','C07','C08','C09','C10','C11',
					              'C12','C13','C14','C15','C16','C17','C18','C19','C20','C21','C22','C23',
					              'C24','C25','C26','C30','C31','C32','C33','C34','C37','C38','C39','C40',
					              'C41','C43','C45','C46','C47','C48','C49','C50','C51','C52','C53','C54',
					              'C55','C56','C57','C58','C60','C61','C62','C63','C64','C65','C66','C67',
					              'C68','C69','C70','C71','C72','C73','C74','C75','C76','C81','C82','C83',
					              'C84','C85','C88','C90','C91','C92','C93','C94','C95','C96','C97') then CC_GRP_14 = 1;
					LABEL CC_GRP_14 = 'Cancer';
					
					/* Moderate or Severe Liver Disease */
					if DX(i) IN: ('K704','K711','K721','K729','K765','K766','K767','I850','I859','I864','I982') then CC_GRP_15 = 1;
					LABEL CC_GRP_15 = 'Moderate or Severe Liver Disease';
					
					/* Metastatic Carcinoma */
					if DX(i) IN: ('C77','C78','C79','C80') then CC_GRP_16 = 1;
					LABEL CC_GRP_16 = 'Metastatic Carcinoma';
					
					/* AIDS/HIV */
					if DX(i) IN: ('B20','B21','B22','B24') then CC_GRP_17 = 1;
					LABEL CC_GRP_17 = 'AIDS/HIV';
					
				end; /* end do i loop */
			end; /* end date window check */
		end; /* end non-missing date check */

		/* Count total number of groups for each record */
		TOT_GRP = CC_GRP_1  + CC_GRP_2  + CC_GRP_3  + CC_GRP_4  + CC_GRP_5  + CC_GRP_6  + CC_GRP_7  + CC_GRP_8  +
		          CC_GRP_9  + CC_GRP_10 + CC_GRP_11 + CC_GRP_12 + CC_GRP_13 + CC_GRP_14 + CC_GRP_15 + CC_GRP_16 +
		          CC_GRP_17;
		LABEL TOT_GRP = 'Total CCI Groups per record';
		
		drop i; /* Drop temporary array index variable */
	run;
    
	options notes ;
	%put ;
	%put NOTE: _Charlson Finished &out created ;
	%put ;	
	%goto exit ;
	%out1:
		%put ERROR: Prior Step failed with an Error submit a null data step to correct ;
		%goto exit ;
	%out2:
		%put ERROR: Input Data Was Not Defined;
		%goto exit ;
	%out3:
		%put ERROR: Input Data &libname..&data does not exist ;
		%goto exit ;	
	%exit:
	/* Reset SAS options */
	options &opts ; 
%mend _CharlsonICD10;
%_CharlsonICD10(DATA = c_data13, OUT = c_data14, 
addate = addate, refdate = ref_index_date, dx = diagx1-diagx25);
proc freq data=c_data14; table tot_grp; run;

* 15. Combine data;
proc sort data=c_data14 nodupkey; by phn index_date; run;
data c_data14; set c_data14; drop cc_grp: diag:; run;
proc freq data=c_data14; table tot_grp; run;
data c_data15;
	merge c_data12(in = x) c_data14(in = a keep = phn index_date tot_grp);
	by phn index_date;
	if x = 1;
run;
proc freq data=c_data15; table tot_grp; run;

/** Subpart 5: SDOH Duration **/
* 16. Identify SDOH;
** b. NACRS;
data c_data16b;
    set c_data01b;
    /* 1. Define an array for the 3 diagnosis variables */
    array diag[3] $ eddiag1 - eddiag3;
    /* 2. Flag variable for finding a match on the current row */
    length sdoh 8;
    sdoh = 0;
    /* 3. Loop through diagnosis columns 1 to 3 */
    do i = 1 to 3;
        /* Using UPCASE and STRIP prevents issues with lowercase letters or leading spaces */
        if upcase(strip(diag[i])) in: (
        	 'Z55','Z56','Z57', 'Z58', 'Z59', 'Z60', 'Z62', 'Z63', 'Z64', 'Z65') then do;
            sdoh = 1;
            leave; /* Stop checking remaining columns for this row once found */
        end;
    end;
    /* Drop temporary loop index */
    drop i;
run;

** c. DAD;
data c_data16c;
    set c_data01c;
    /* 1. Define an array for the 25 diagnosis variables */
    array diag[25] $ diagx1 - diagx25;
    /* 2. Flag variable for finding a match on the current row */
    length sdoh 8;
    sdoh = 0;
    /* 3. Loop through diagnosis columns 1 to 25 */
    do i = 1 to 25;
        /* Using UPCASE and STRIP prevents issues with lowercase letters or leading spaces */
        if upcase(strip(diag[i])) in: (
        	 'Z55','Z56','Z57', 'Z58', 'Z59', 'Z60', 'Z62', 'Z63', 'Z64', 'Z65') then do;
            sdoh = 1;
            leave; /* Stop checking remaining columns for this row once found */
        end;
    end;
    /* Drop temporary loop index */
    drop i;
run;

* 17. Harmonize files for concatenation;
data c_data17b; set c_data16b; rename regdate = sdohdate; keep phn regdate; run;
data c_data17c; set c_data16c; rename addate = sdohdate; keep phn addate; run;
data c_data17; set c_data17b c_data17c; format sdohdate date9.; run;
proc sort data=c_data17; by phn sdohdate; run;

* 18. Remove duplicates;
proc sort data=c_data17 out=c_data18 nodupkey; by phn; run;

* 19. Merge data;
data c_data19;
	merge c_data15(in = x) c_data18(in = y);
	by phn;
	if x = 1;
	sdoh_yr_dur = (index_date - sdohdate)/365.25;
	format suddate date9.;
run;


data r2r.c_data15; set c_data15; run;
data r2r.c_data01c; set c_data01c; run;
data r2r.master_candidate_pool; set master_candidate_pool; run;

/** Subpart 6: ED Visits from SUD **/
* 20. Merge data;
proc sort data=c_data19 out=c_data19a nodupkey; by phn; run;
data c_data20;
	merge c_data19a(in=x keep=phn index_date r2r) a_data02b(in=y);
	by phn;
	if x = 1;
	if index_date - 14 <= suddate < index_date then sud_2wk = 1;
	else sud_2wk = 0;
	format suddate date9.;
	rename suddate = sud_eddate;
run;
proc sort data=c_data20 nodupkey; by phn descending sud_2wk; run;
proc sort data=c_data20 nodupkey; by phn; run;

* 21. Number of ED visits within 14 days;
data c_data21;
	merge c_data19(in = x) c_data20(in = y keep = phn sud_2wk);
	by phn;
	if x = 1;
run;

/** Part D: Propensity Score Matching **/
data c_data22;
    set c_data15;
    /* Bin age into 2-year bands */
    age_band = floor(age_yr_index / 2);
    /* Bin SUD duration into 1-year bands */
    sud_dur_band = floor(sud_yr_dur/2);
    /* Bin SDOH duration into 1-year bands */
    * sdoh_dur_band = floor(sdoh_yr_dur/2);
run;

/* Patient identifier variable */
%let control_id = phn;
%let treated_id = phn;

%macro run_psmatch(indata=, outdata=, seed=0605);
    proc psmatch data=&indata region=treated;
        class treated block male hp_any_1yr overdose oat_disc_2wk age_band sud_dur_band;
        psmodel treated(treated='1') = 
            male index_date op_num_1yr ed_num_1yr hp_any_1yr 
            age_yr_index sud_yr_dur overdose oat_disc_2wk tot_grp;
        match method=greedy(k=1 order=random(seed=&seed)) 
              stat=lps 
              caliper=0.2
              exact=(male block age_band sud_dur_band);
        output out(obs=match)=&outdata 
               matchid=match_pair_id
               lps=_LPS_;
    run;

    proc sort data=&outdata; by match_pair_id descending treated; run;

    data &outdata;
        set &outdata;
        by match_pair_id;
        retain _treated_lps;
        if treated = 1 then _treated_lps = _LPS_;
        _MATCHDIST_ = abs(_LPS_ - _treated_lps);
    run;
%mend;

/* Initialize */
data _current_pool; set c_data22; run;
proc datasets library=work nolist; delete _final_matches; run; quit;
%macro iterative_match(max_iter=5);
    %do i = 1 %to &max_iter;

        %run_psmatch(indata=_current_pool, outdata=_round_match, seed=%eval(605+&i));

        proc sql noprint;
            select count(*) into :n_matches trimmed from _round_match;
        quit;
        %if &n_matches = 0 %then %do;
            %put NOTE: No more matches possible. Stopping at iteration &i.;
            %goto done;
        %end;

        proc sort data=_round_match; by &control_id _MATCHDIST_; run;

        data _round_keep _round_bumped;
            set _round_match;
            by &control_id;
            if treated = 0 then do;
                if first.&control_id then output _round_keep;
                else output _round_bumped;
            end;
            else output _round_keep;
        run;

        proc sql;
            create table _bumped_pairs as
            select distinct match_pair_id from _round_bumped;

            create table _treated_to_rematch as
            select b.&treated_id
            from _round_match b
            where b.treated = 1
              and b.match_pair_id in (select match_pair_id from _bumped_pairs);
        quit;

        proc sql;
            create table _round_keep_final as
            select * from _round_keep
            where not (treated = 1 and match_pair_id in 
                       (select match_pair_id from _bumped_pairs));
        quit;

        /* Accumulate confirmed matches */
        %if %sysfunc(exist(_final_matches)) %then %do;
            proc append base=_final_matches data=_round_keep_final force; run;
        %end;
        %else %do;
            data _final_matches;
                set _round_keep_final;
            run;
        %end;

        proc sql noprint;
            select count(*) into :n_bumped trimmed from _treated_to_rematch;
        quit;
        %if &n_bumped = 0 %then %do;
            %put NOTE: All treated patients matched with no reuse after iteration &i.;
            %goto done;
        %end;

        proc sql;
            create table _used_controls as
            select distinct &control_id from _final_matches where treated = 0;

            create table _current_pool as
            select * from c_data22
            where (treated = 1 and &treated_id in (select &treated_id from _treated_to_rematch))
               or (treated = 0 and &control_id not in (select &control_id from _used_controls));
        quit;

    %end;
    %put WARNING: Reached max iterations (&max_iter) with unresolved duplicates.;
    %done:
%mend;
%iterative_match(max_iter=5);

proc sort data=_final_matches out=d_data02; by match_pair_id treated; run;
proc sql;
    select count(*) as n_control_rows, 
           count(distinct &control_id) as n_unique_controls
    from d_data02
    where treated = 0;
quit;
