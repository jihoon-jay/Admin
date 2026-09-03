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

* 1. Restrict to people who are alive or died after SUD identification;
data a_setup01; set r2r.sud; if deathdate = . or suddate <= deathdate; run;
proc sort data=a_setup01 nodupkey; by phn; run;

* 2. Define EOF;
data a_setup02;
	set a_setup01;
	if r2rdate = . then r2r = 0; else r2r = 1;
	* Crete fake dates;
	if r2r = 1 then indexdate = r2rdate; else indexdate = intnx('year', suddate, 5, 'same');
	if deathdate = . then eof = '31dec2025'd; else eof = deathdate;
	its_start = intnx('year', indexdate, -1, 'same');
	its_stop  = min(intnx('year', indexdate, 1, 'same') - 1, deathdate, '31dec2025'd);
	format indexdate date9. eof date9. its_start date9. its_stop date9.;
run;

* 3. Create monthly skeleton per patient;
data a_setup03;
    set a_setup02;
    format win_start win_stop date9.;
    cur_start = its_start;   
    do while (cur_start <= its_stop);
        win_start = cur_start;
        win_stop  = min(intnx('month', win_start, 1, 'same') - 1, its_stop);        
        rel_month = intck('month', indexdate, win_start, 'continuous');        
        p_days   = (win_stop - win_start) + 1;
        p_months = p_days / 30.4375;        
        output;
        cur_start = win_stop + 1;
    end;    
    keep phn rel_month win_start win_stop p_days p_months r2r;
run;
** a. Prepare data;
data a_setup03a; merge b_msp(in = x) a_setup02(in = y); by phn; if y = 1; run;
data a_setup03b; merge b_nacrs(in = x) a_setup02(in = y); by phn; if y = 1; run;
data a_setup03c; merge b_dad(in = x) a_setup02(in = y); by phn; if y = 1; run;

* 4. Join with claims to handle multiple events per window;
** a. MSP;
proc sql;
    create table a_setup04a as
    select 
        a.phn, a.r2r, a.rel_month, a.win_start, a.win_stop, a.p_days, a.p_months,
        count(b.servdate) as event_count
    from a_setup03 as a
    left join a_setup03a as b
        on a.phn = b.phn
       and b.servdate >= a.win_start 
       and b.servdate <= a.win_stop
    group by a.phn, a.rel_month, a.win_start, a.win_stop, a.p_days, a.p_months
    order by a.phn, a.rel_month;
quit;
** b. NACRS;
proc sql;
    create table a_setup04b as
    select 
        a.phn, a.r2r, a.rel_month, a.win_start, a.win_stop, a.p_days, a.p_months,
        count(b.regdate) as event_count
    from a_setup03 as a
    left join a_setup03b as b
        on a.phn = b.phn
       and b.regdate >= a.win_start 
       and b.regdate <= a.win_stop
    group by a.phn, a.rel_month, a.win_start, a.win_stop, a.p_days, a.p_months
    order by a.phn, a.rel_month;
quit;
** c. DAD;
proc sql;
    create table a_setup04c as
    select 
        a.phn, a.r2r, a.rel_month, a.win_start, a.win_stop, a.p_days, a.p_months,
        count(b.addate) as event_count
    from a_setup03 as a
    left join a_setup03c as b
        on a.phn = b.phn
       and b.addate >= a.win_start 
       and b.addate <= a.win_stop
    group by a.phn, a.rel_month, a.win_start, a.win_stop, a.p_days, a.p_months
    order by a.phn, a.rel_month;
quit;

* 5. Sum across time periods;
** a. MSP;
proc sql;
	create table a_setup05a as
	select *, sum(event_count) as op,
		sum(p_months) as person_months
	from a_setup04a
	group by r2r, rel_month
	order by r2r, rel_month;
quit;
proc sort data=a_setup05a nodupkey; by r2r rel_month; run;
** b. NACRS;
proc sql;
	create table a_setup05b as
	select *, sum(event_count) as ed,
		sum(p_months) as person_months
	from a_setup04b
	group by r2r, rel_month
	order by r2r, rel_month;
quit;
proc sort data=a_setup05b nodupkey; by r2r rel_month; run;
** c. DAD;
proc sql;
	create table a_setup05c as
	select *, sum(event_count) as hp,
		sum(p_months) as person_months
	from a_setup04c
	group by r2r, rel_month
	order by r2r, rel_month;
quit;
proc sort data=a_setup05c nodupkey; by r2r rel_month; run;

* 6. Calculate incidence rate;
** a. MSP;
data a_setup06a; 
	set a_setup05a; 
	ir_op = (op / person_months)*1000; 
	keep r2r rel_month op person_months ir_op; 
run;
** b. NACRS;
data a_setup06b; 
	set a_setup05b; 
	ir_ed = (ed / person_months)*1000; 
	keep r2r rel_month ed person_months ir_ed; 
run;
** c. DAD;
data a_setup06c; 
	set a_setup05c; 
	ir_hp = (hp / person_months)*1000; 
	keep r2r rel_month hp person_months ir_hp; 
run;

* 7. Combine data to set up for ITS;
data a_setup07;
	merge a_setup06a(in = x) a_setup06b(in = y) a_setup06c(in = z);
	by r2r rel_month;
	if x = 1;
	if rel_month < 0 then level = 0; else level = 1;
	if rel_month <= 0 then trend = 0; else trend + 1;
	rename r2r = group rel_month = time;
run;

/* Part B: Hospitalizations */
* 1. Cause-specific hospitalizations;
** a. Overdose;
data b_hosp01a;
	set a_setup03c;
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
** b. SUD;
data b_hosp01b;
	set a_setup03c;
	/* 1. Define an array for the 25 diagnosis variables */
    array diag[25] $ diagx1 - diagx25;
    /* 2. Flag variable for finding a match on the current row */
    length sud 8;
    sud = 0;
    /* 3. Loop through diagnosis columns 1 to 25 */
    do i = 1 to 25;
        /* Using UPCASE and STRIP prevents issues with lowercase letters or leading spaces */
        if upcase(strip(diag[i])) in: (
        	 'F10', 'F11', 'F12', 'F13', 'F14', 'F15', 'F16', 'F17', 'F18') then do;
            sud = 1;
            leave; /* Stop checking remaining columns for this row once found */
        end;
    end;
    /* Drop temporary loop index */
    drop i;
run;
** c. IRI;
data b_hosp01c;
	set a_setup03c;
	/* 1. Define an array for the 25 diagnosis variables */
    array diag[25] $ diagx1 - diagx25;
    /* 2. Flag variable for finding a match on the current row */
    length infection 8;
    infection = 0;
    /* 3. Loop through diagnosis columns 1 to 25 */
    do i = 1 to 25;
        /* Using UPCASE and STRIP prevents issues with lowercase letters or leading spaces */
        if upcase(strip(diag[i])) in: (
        	/* SSTI */
        	'I80', 'L97', 'L988', 'M793', 'A480', 'G06', 'G09',
        	'K630', 'K650', 'K750', 'L02', 'L03', 'M5402', 'M726', 'N10',
        	/* Endocarditis */
        	'B376', 'I33', 'I34', 'I35', 'I36', 'I37', 'I38', 'I39',
        	/* Bacteremia / Sepsis */
        	'A40', 'A41', 'I269', 'I400', 'R572', 'R651', 'R659',
        	/* Osteomyelitis & Myositis */
        	'M86', 'M899', 'M60',
        	/* HIV */
        	'B20', 'B21', 'B22', 'B23', 'B24',
        	/* HCV*/
        	'B171', 'B182', 'B192', 'Z2252'
        	 ) then do;
            infection = 1;
            leave; /* Stop checking remaining columns for this row once found */
        end;
    end;
    /* Drop temporary loop index */
    drop i;
run;

* 2. Combine cause-specific hospitalizations;
data b_hosp02;
	merge b_hosp01a(in = a) b_hosp01b(in = b) b_hosp01c(in = c);
	by phn addate sepdate;
	if a = 1;
	drop diagx:;
run;

* 3. Join with claims to handle multiple events per window;
proc sql;
    create table b_hosp03 as
    select 
        a.phn, a.r2r, a.rel_month, a.win_start, a.win_stop, a.p_months,
        /* SUM(1/0) or SUM(CASE) correctly counts positive occurrences */
        sum(case when b.od = 1 then 1 else 0 end) as hp_od,
        sum(case when b.sud = 1 then 1 else 0 end) as hp_sud,
        sum(case when b.infection = 1 then 1 else 0 end) as hp_inf
    from a_setup03 as a
    left join b_hosp02 as b
        on a.phn = b.phn
       and b.addate >= a.win_start 
       and b.addate <= a.win_stop
    group by a.phn, a.r2r, a.rel_month, a.win_start, a.win_stop, a.p_months
    order by a.phn, a.rel_month;
quit;

* 4. Sum across time periods;
proc sql;
	create table b_hosp04 as
	select *, sum(hp_od) as overdose_hosp,
		sum(hp_sud) as substance_hosp,
		sum(hp_inf) as infection_hosp,
		sum(p_months) as person_months
	from b_hosp03
	group by r2r, rel_month
	order by r2r, rel_month;
quit;
proc sort data=b_hosp04 nodupkey; by r2r rel_month; run;

* 5. Calculate incidence rate and set up for ITS;
data b_hosp05; 
	set b_hosp04; 
	ir_od = (overdose_hosp / person_months)*1000;
	ir_sud = (substance_hosp / person_months)*1000;
	ir_inf = (infection_hosp / person_months)*1000;
	if rel_month < 0 then level = 0; else level = 1;
	if rel_month <= 0 then trend = 0; else trend + 1;
	rename r2r = group rel_month = time;
	keep r2r rel_month person_months ir_: level trend; 
run;

/* Part C: Re-admissions */
* 1. Calculate the gap between any two SUD events;
proc sort data=a_setup03c; by phn addate; run;
data c_readmission01;
	set a_setup03c;
	by phn;
	lag_sepdate = lag(sepdate);
	format lag_sepdate date9.;
	if first.phn then do;
		lag_sepdate = .;
		gap = .;
		_07ra = 0;
		_30ra = 0;
	end;
	else do;
	gap = addate - lag_sepdate;
	* 7-day re-admissions;
		if 0 <= gap <= 7 then _07ra = 1; else _07ra = 0;
	* 30-day re-admissions;
		if 0 <= gap <= 30 then _30ra = 1; else _30ra = 0;
	end;
	drop diagx:;
run;

* 2. Join with claims to handle multiple events per window;
proc sql;
    create table c_readmission02 as
    select 
        a.phn, a.r2r, a.rel_month, a.win_start, a.win_stop, a.p_months,
        /* Count readmissions indexed by the admission date of the readmission */
        coalesce(sum(b._07ra), 0) as _07dra,
        coalesce(sum(b._30ra), 0) as _30dra
    from a_setup03 as a
    left join c_readmission01 as b
        on a.phn = b.phn
       and b.addate >= a.win_start 
       and b.addate <= a.win_stop
    group by a.phn, a.r2r, a.rel_month, a.win_start, a.win_stop, a.p_months
    order by a.phn, a.rel_month;
quit;
proc freq data=c_readmission02; table _07dra _30dra; run;

* 3. Sum across time periods;
proc sql;
	create table c_readmission03 as
	select r2r, rel_month, 
		sum(_07dra) as _07day_readmission,
		sum(_30dra) as _30day_readmission,
		sum(p_months) as person_months
	from c_readmission02
	group by r2r, rel_month
	order by r2r, rel_month;
quit;
proc sort data=c_readmission03 nodupkey; by r2r rel_month; run;

* 4. Calculate incidence rate and set up for ITS;
data c_readmission04; 
    set c_readmission03;
    by r2r rel_month;
    /* Rates per 1,000 Person-Months */
    if person_months > 0 then do;
        ir_07d = (_07day_readmission / person_months) * 1000;
        ir_30d = (_30day_readmission / person_months) * 1000;
    end;
    else do;
        ir_07d = 0;
        ir_30d = 0;
    end;
    /* ITS Parameterization */
    /* level = Step change post-intervention; trend = Slope change post-intervention */
    if rel_month < 0 then level = 0; else level = 1;
	if rel_month <= 0 then trend = 0; else trend + 1;
    rename r2r = group rel_month = time;
    keep r2r rel_month person_months _07day_readmission _30day_readmission ir_07d ir_30d level trend; 
run;

/* ITS Data */
data r2r.its_healthserviceuse; set a_setup07; run;
data r2r.its_hospitalizations; set b_hosp05; run;
data r2r.its_readmissions; set c_readmission04; run;

/* Part D: Cheque Day Setup */
data d_cheque; set a_setup03; if '01jan2022'd < win_start <= '31dec2025'd; run;
data d_cheque_windows;
    input cheque_date :date9.;
    chq_win_start = cheque_date;
    chq_win_stop  = cheque_date + 6; /* 7-day Cheque Week window */
    format cheque_date chq_win_start chq_win_stop DATE9.;
    datalines;
26JAN2022
23FEB2022
30MAR2022
27APR2022
25MAY2022
29JUN2022
27JUL2022
24AUG2022
28SEP2022
26OCT2022
23NOV2022
21DEC2022
18JAN2023
15FEB2023
22MAR2023
19APR2023
17MAY2023
21JUN2023
19JUL2023
23AUG2023
20SEP2023
25OCT2023
22NOV2023
20DEC2023
24JAN2024
28FEB2024
27MAR2024
24APR2024
29MAY2024
26JUN2024
24JUL2024
28AUG2024
25SEP2024
23OCT2024
20NOV2024
18DEC2024
15JAN2025
19FEB2025
19MAR2025
16APR2025
21MAY2025
25JUN2025
23JUL2025
27AUG2025
24SEP2025
22OCT2025
19NOV2025
17DEC2025
;
run;

/********************************************************************************
 * Step 2: Expand Patient Monthly Windows (cheque01) to Daily Person-Time 
 * and Assign the Cheque Week Flag (1 vs 0)
 ********************************************************************************/
/* A. Expand each patient's window into daily rows */
data d_setup_daily;
    set d_cheque;
    do date = win_start to win_stop;
        format date DATE9.;
        output;
    end;
run;

/* B. Flag days that fall into a 7-day cheque week */
proc sql;
    create table d_setup_daily_flagged as
    select a.phn, a.r2r, a.rel_month, a.win_start, a.win_stop, a.date,
        case when b.cheque_date is not missing then 1 else 0 end as is_cheque_wk
    from d_setup_daily as a
    left join d_cheque_windows as b
        on a.date >= b.chq_win_start 
       and a.date <= b.chq_win_stop
    order by a.phn, a.rel_month, a.date;
quit;

/********************************************************************************
 * Step 3: Join Events (a_setup03a) & Aggregate Person-Time + Events 
 * Stratified by Cheque Week vs. Other Days
 ********************************************************************************/
** a. MSP;
proc sql;
    create table d_stratified03a as
    select a.phn, a.r2r, a.rel_month, a.win_start, a.win_stop, a.is_cheque_wk,
        /* Person-time in days */
        count(distinct a.date) as p_days,
        /* Person-time converted to person-months (Days / 30.4375) */
        count(distinct a.date) / 30.4375 as p_months,
        /* Count events occurring on these specific days */
        count(b.servdate) as event_count
    from d_setup_daily_flagged as a
    left join a_setup03a as b
        on a.phn = b.phn
       and a.date = b.servdate /* Exact date match for event attribution */
    group by a.phn, a.r2r, a.rel_month, a.win_start, a.win_stop, a.is_cheque_wk
    order by a.phn, a.rel_month, a.is_cheque_wk descending;
quit;
** b. NACRS;
proc sql;
    create table d_stratified03b as
    select a.phn, a.r2r, a.rel_month, a.win_start, a.win_stop, a.is_cheque_wk,
        /* Person-time in days */
        count(distinct a.date) as p_days,
        /* Person-time converted to person-months (Days / 30.4375) */
        count(distinct a.date) / 30.4375 as p_months,
        /* Count events occurring on these specific days */
        count(b.regdate) as event_count
    from d_setup_daily_flagged as a
    left join a_setup03b as b
        on a.phn = b.phn
       and a.date = b.regdate /* Exact date match for event attribution */
    group by a.phn, a.r2r, a.rel_month, a.win_start, a.win_stop, a.is_cheque_wk
    order by a.phn, a.rel_month, a.is_cheque_wk descending;
quit;
** c. DAD;
proc sql;
    create table d_stratified03c as
    select a.phn, a.r2r, a.rel_month, a.win_start, a.win_stop, a.is_cheque_wk,
        /* Person-time in days */
        count(distinct a.date) as p_days,
        /* Person-time converted to person-months (Days / 30.4375) */
        count(distinct a.date) / 30.4375 as p_months,
        /* Count events occurring on these specific days */
        count(b.addate) as event_count
    from d_setup_daily_flagged as a
    left join a_setup03c as b
        on a.phn = b.phn
       and a.date = b.addate /* Exact date match for event attribution */
    group by a.phn, a.r2r, a.rel_month, a.win_start, a.win_stop, a.is_cheque_wk
    order by a.phn, a.rel_month, a.is_cheque_wk descending;
quit;

* 4. Aggregate individual data into ecological data;
** a. MSP;
proc sql;
	create table d_stratified04a as
	select *, sum(event_count) as op, sum(p_months) as person_months
	from d_stratified03a
	group by r2r, rel_month, is_cheque_wk
	order by r2r, rel_month, is_cheque_wk;
quit;
proc sort data=d_stratified04a nodupkey; by r2r rel_month is_cheque_wk; run;
** b. NACRS;
proc sql;
	create table d_stratified04b as
	select *, sum(event_count) as ed, sum(p_months) as person_months
	from d_stratified03b
	group by r2r, rel_month, is_cheque_wk
	order by r2r, rel_month, is_cheque_wk;
quit;
proc sort data=d_stratified04b nodupkey; by r2r rel_month is_cheque_wk; run;
** c. DAD;
proc sql;
	create table d_stratified04c as
	select *, sum(event_count) as hp, sum(p_months) as person_months
	from d_stratified03c
	group by r2r, rel_month, is_cheque_wk
	order by r2r, rel_month, is_cheque_wk;
quit;
proc sort data=d_stratified04c nodupkey; by r2r rel_month is_cheque_wk; run;

* 5. Calculate incidence rate;
** a. MSP;
data d_stratified05a; 
	set d_stratified04a; 
	ir_op = (op / person_months)*1000; 
	keep r2r rel_month is_cheque_wk op person_months ir_op; 
run;
** b. NACRS;
data d_stratified05b; 
	set d_stratified04b; 
	ir_ed = (ed / person_months)*1000; 
	keep r2r rel_month is_cheque_wk ed person_months ir_ed; 
run;
** c. DAD;
data d_stratified05c; 
	set d_stratified04c; 
	ir_hp = (hp / person_months)*1000; 
	keep r2r rel_month is_cheque_wk hp person_months ir_hp; 
run;

* 6. Combine data to set up for ITS;
data d_stratified06;
	merge d_stratified05a(in = x) d_stratified05b(in = y) d_stratified05c(in = z);
	by r2r rel_month is_cheque_wk;
	if x = 1;
	drop op ed hp;
	if rel_month < 0 then level = 0; else level = 1;
	if rel_month <= 0 then trend = 0; else trend + 1;
	rename r2r = group rel_month = time;
run;

* 7. Stratify datasets;
data d_stratified07a; set d_stratified06; if is_cheque_wk = 1; run;
data d_stratified07b; set d_stratified06; if is_cheque_wk = 0; run;
data r2r.its_cheque1; set d_stratified07a; run;
data r2r.its_cheque0; set d_stratified07b; run;