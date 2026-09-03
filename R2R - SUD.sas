libname r2r "/home/u35232324/r2r";

/** SUD Setup **/
* 1. Identify date;
** a. DAD;
/* Step 1: Flag inpatient visits and extract diagnosis codes from DAD */
data a_data01_dad_flagged;
    set r2r.dad;
    /* Array for DAD diagnosis columns */
    array diag[25] $ diagx1 - diagx25;
    aud = 0; oud = 0; tud = 0; cud = 0;
    shaud = 0; stud = 0; hud = 0; iud = 0;
    do i = 1 to 25;
        d = upcase(strip(diag[i]));
        if d = '' then continue;
        
        /* AUD: Alcohol */
        if d in: ('F10', 'G312', 'G621', 'G721', 'I426', 'K292', 'K700',
                  'K701', 'K702', 'K703', 'K704', 'K709', 'K852', 'K860', 'Z502',
                  '291', '303', '3050', '3575', '4255', '5353', '5710', 
                  '5711', '5712', '5713', 'V113', 'V791') then aud = 1;       
        /* OUD: Opioids */
        if d in: ('F11', '3040', '3047', '3055') then oud = 1;    
        /* TUD: Tobacco */
        if d in: ('F17', '3051', 'Z720') then tud = 1;
        /* CUD: Cannabis */
        if d in: ('F12', '3043', '3052') then cud = 1;
        /* SHAUD: Sedatives / Hypnotics / Anxiolytics */
        if d in: ('F13', '3041', '3054') then shaud = 1;
        /* StUD: Stimulants (Cocaine / Amphetamines) */
        if d in: ('F14', 'F15', '3042', '3044', '3056', '3057') then stud = 1;
        /* HUD: Hallucinogens */
        if d in: ('F16', '3045', '3053') then hud = 1;
        /* IUD: Inhalants */
        if d in: ('F18', '3046', '3058') then iud = 1;
    end;
    /* Retain records with at least one SUD diagnosis */
    if aud=1 or oud=1 or tud=1 or cud=1 or shaud=1 or stud=1 or hud=1 or iud=1;
    drop i d;
run;

/* Step 2: Macro for 1-Claim Ascertainment (Single inpatient Visit = Case) */
%macro get_dad_cases(disorder=);
    proc sql;
        create table case_dad_&disorder as
        select 
            phn,
            min(addate) as &disorder._date format=date9. /* Earliest inpatient visit date */
        from a_data01_dad_flagged
        where &disorder = 1
        group by phn
        order by phn;
    quit;
%mend get_dad_cases;

/* Step 3: Run macro across all 8 SUD categories */
%get_dad_cases(disorder=aud);   %get_dad_cases(disorder=oud);
%get_dad_cases(disorder=tud);   %get_dad_cases(disorder=cud);
%get_dad_cases(disorder=shaud); %get_dad_cases(disorder=stud);
%get_dad_cases(disorder=hud);   %get_dad_cases(disorder=iud);

/* Step 4: Merge into wide format (1 row per PHN) */
data a_data01_dad;
    merge case_dad_aud   case_dad_oud   case_dad_tud   case_dad_cud
          case_dad_shaud case_dad_stud case_dad_hud case_dad_iud;
    by phn;
run;

** b. NACRS;
/* Step 1: Flag ED visits and extract diagnosis codes from NACRS */
data a_data01_nacrs_flagged;
    set r2r.nacrs;
    /* Array for NACRS diagnosis columns */
    array diag[3] $ eddiag1 - eddiag3;
    aud = 0; oud = 0; tud = 0; cud = 0;
    shaud = 0; stud = 0; hud = 0; iud = 0;
    do i = 1 to 3;
        d = upcase(strip(diag[i]));
        if d = '' then continue;
        /* AUD: Alcohol */
        if d in: ('F10', 'G312', 'G621', 'G721', 'I426', 'K292', 'K700',
                  'K701', 'K702', 'K703', 'K704', 'K709', 'K852', 'K860', 'Z502',
                  '291', '303', '3050', '3575', '4255', '5353', '5710', 
                  '5711', '5712', '5713', 'V113', 'V791') then aud = 1;         
        /* OUD: Opioids */
        if d in: ('F11', '3040', '3047', '3055') then oud = 1;
        /* TUD: Tobacco */
        if d in: ('F17', '3051', 'Z720') then tud = 1;
        /* CUD: Cannabis */
        if d in: ('F12', '3043', '3052') then cud = 1;
        /* SHAUD: Sedatives / Hypnotics / Anxiolytics */
        if d in: ('F13', '3041', '3054') then shaud = 1;
        /* StUD: Stimulants (Cocaine / Amphetamines) */
        if d in: ('F14', 'F15', '3042', '3044', '3056', '3057') then stud = 1;
        /* HUD: Hallucinogens */
        if d in: ('F16', '3045', '3053') then hud = 1;
        /* IUD: Inhalants */
        if d in: ('F18', '3046', '3058') then iud = 1;
    end;
    /* Retain records with at least one SUD diagnosis */
    if aud=1 or oud=1 or tud=1 or cud=1 or shaud=1 or stud=1 or hud=1 or iud=1;
    drop i d;
run;

/* Step 2: Macro for 1-Claim Ascertainment (Single ED Visit = Case) */
%macro get_nacrs_cases(disorder=);
    proc sql;
        create table case_nacrs_&disorder as
        select 
            phn,
            min(regdate) as &disorder._date format=date9. /* Earliest ED visit date */
        from a_data01_nacrs_flagged
        where &disorder = 1
        group by phn
        order by phn;
    quit;
%mend get_nacrs_cases;

/* Step 3: Run macro across all 8 SUD categories */
%get_nacrs_cases(disorder=aud);   %get_nacrs_cases(disorder=oud);
%get_nacrs_cases(disorder=tud);   %get_nacrs_cases(disorder=cud);
%get_nacrs_cases(disorder=shaud); %get_nacrs_cases(disorder=stud);
%get_nacrs_cases(disorder=hud);   %get_nacrs_cases(disorder=iud);

/* Step 4: Merge into wide format (1 row per PHN) */
data a_data01_nacrs;
    merge case_nacrs_aud   case_nacrs_oud   case_nacrs_tud   case_nacrs_cud
          case_nacrs_shaud case_nacrs_stud case_nacrs_hud case_nacrs_iud;
    by phn;
run;

** c. MSP;
/* Step 1: Flag single medical claims in outpatient data */
data a_data01_msp_flagged;
    set r2r.msp;
    array diag[3] $ diagcd1 - diagcd3;
    aud = 0; oud = 0; tud = 0; cud = 0;
    shaud = 0; stud = 0; hud = 0; iud = 0;
    do i = 1 to 3;
        d = upcase(strip(diag[i]));
        if d = '' then continue;
        /* 2-Claim Disorders */
        if d in: ('291', '303', '3050', '3575', '4255', '5353', '5710', 
                  '5711', '5712', '5713', 'V113', 'V791') then aud = 1;
        if d in: ('3040', '3047', '3055') then oud = 1;
        if d in: ('3051', 'Z720') then tud = 1;
        if d in: ('3043', '3052') then cud = 1;
        /* 1-Claim Disorders */
        if d in: ('3041', '3054') then shaud = 1;
        if d in: ('3042', '3044', '3056', '3057') then stud = 1;
        if d in: ('3045', '3053') then hud = 1;
        if d in: ('3046', '3058') then iud = 1;
    end;
    if aud=1 or oud=1 or tud=1 or cud=1 or shaud=1 or stud=1 or hud=1 or iud=1;
    drop i d;
    rename phnnum = phn clntgndr = gender clntbrdt = dob toservdt = servdate;
run;

/* Step 2A: Macro for 2-Claim Requirement (Rolling — any 2 visits within 365 days) */
%macro get_sud_cases_2claim(disorder=);
    proc sort data=a_data01_msp_flagged(where=(&disorder=1))
              out=_&disorder._sorted;
        by phn servdate;
    run;
    data _&disorder._gap;
        set _&disorder._sorted;
        by phn;
        lag_date = lag(servdate);
        format lag_date date9.;
        if first.phn then lag_date = .;
        gap = servdate - lag_date;
    run;
    proc sql;
        create table case_&disorder as
        select phn, min(servdate) as &disorder._date format=date9.
        from _&disorder._gap
        where gap is not missing and gap <= 365
        group by phn
        order by phn;
    quit;
    proc datasets library=work nolist; 
    	delete _&disorder._sorted _&disorder._gap; 
    quit;
%mend get_sud_cases_2claim;

/* Step 2B: Macro for 1-Claim Requirement */
%macro get_sud_cases_1claim(disorder=);
    proc sql;
        create table case_&disorder as
        select 
            phn,
            min(servdate) as &disorder._date format=date9.
        from a_data01_msp_flagged
        where &disorder = 1
        group by phn
        order by phn;
    quit;
%mend get_sud_cases_1claim;

/* Step 3: Run macros for all 8 disorders */
%get_sud_cases_2claim(disorder=aud);  %get_sud_cases_2claim(disorder=oud);
%get_sud_cases_2claim(disorder=tud);  %get_sud_cases_2claim(disorder=cud);
%get_sud_cases_1claim(disorder=shaud); %get_sud_cases_1claim(disorder=stud);
%get_sud_cases_1claim(disorder=hud);   %get_sud_cases_1claim(disorder=iud);

/* Step 4: Merge into a single wide dataset (1 row per PHN) */
data a_data01_msp;
    merge case_aud  case_oud  case_tud  case_cud
          case_shaud case_stud case_hud case_iud;
    by phn;
run;

** d. PNET;
/* Step 1: Flag single medical claims in PNET */
data a_data01_pnet_flagged;
	set r2r.pnet;
	length aud 8 oud 8 tud 8;
    aud = 0; oud = 0; tud = 0;
    /* AUD Meds */
    if din_pin in (
    	2542, 2534, 2041375, 2041391, 66124089, 66124085, 66124087,
    	14958, 2213826, 2444275, 2451883, 2158655, 66129170, 2293269)
    then aud = 1;
    /* OUD Meds */
    if din_pin in (
    	22123340, 22123346, 22123347, 22123348, 22123349, 22123357,
		22123374, 2242963, 2242964, 2295695, 2295709, 2408090,
		2408104, 2424851, 2424878, 2453908, 2453916, 2468085,
		2468093, 2474921, 2483084, 2483092, 2502313, 2502321,
		2502348, 2502356, 2517175, 2517183, 2524996,2525003,
		655619, 655627, 66128314, 66128315, 66128316, 66128328,
		66128329, 66128330, 66128331,
    	66999990, 66999991, 66999992, 66999993, 66999997, 66999998, 
        66999999, 67000000, 67000001, 67000002, 67000003, 67000004,
        67000005, 67000006, 67000007, 67000008, 67000009, 67000010, 
        67000011, 67000012, 67000013, 67000014, 67000015, 67000016, 
        67000017, 67000018, 67000019, 67000020, 2394596, 2244290, 
        781460, 781479, 9858127, 9858128, 999792, 999793)
    then oud = 1;
    /* TUD Meds */
    if din_pin in (
    	580317, 580325, 1943057, 1943065, 1943073, 1968106, 
    	1968114, 1968122, 2028697, 2029405, 2029413, 2057735,
		2057743, 2065738,2065754, 2065762, 2091933, 2091941,
		2093111, 2093138, 2093146, 2238441, 2241226, 2241227,
		2241228, 2241742, 2291177, 2291185, 2298309, 2362066,
		2419882, 2419890, 2426226, 2426234, 2426781, 2435675,
		2458500, 2458519, 2485869, 2542951, 2542978, 2542986,
		2546949, 2546957, 2546965, 2554445, 2554453, 2559897,
		2559900, 80044503, 80044515, 80044518, 80069471, 80069513,
		80110858, 80112095)
    then tud = 1;
    if aud = 1 or oud = 1 or tud = 1;
    rename clnt_key = phn srv_date = servdate;
run;

/* Step 2: Macro for 1-Claim Ascertainment (Single Claim = Case) */
%macro get_pnet_cases(disorder=);
    proc sql;
        create table case_pnet_&disorder as
        select 
            phn,
            min(servdate) as &disorder._date format=date9.
        from a_data01_pnet_flagged
        where &disorder = 1
        group by phn
        order by phn;
    quit;
%mend get_pnet_cases;

/* Step 3: Run macro across all 8 SUD categories */
%get_pnet_cases(disorder=aud);   %get_pnet_cases(disorder=oud); %get_pnet_cases(disorder=tud);

/* Step 4: Merge into a single wide dataset (1 row per PHN) */
data a_data01_pnet; merge case_aud  case_oud  case_tud; by phn; run;


/* Example: Combining across administrative databases */
/* Ensure all datasets are sorted by PHN prior to merging */
data r2r_bl; 
	set r2r.df; 
	rename bc_phn = phn date_of_r2r_admission = indexdate; 
	keep bc_phn date_of_r2r_admission; 
	format date_of_r2r_admission date9.;
run;
proc sort data=r2r_bl; by phn; run;
proc sort data=a_data01_msp; by phn; run;
proc sort data=a_data01_nacrs; by phn; run;
proc sort data=a_data01_dad; by phn; run;
proc sort data=a_data01_pnet; by phn; run;

data final_sud_cohort;
    /* MERGE horizontally by PHN (r2r_bl serves as the master baseline cohort) */
    merge r2r_bl (in=in_bl)
          a_data01_msp (rename=(aud_date=aud_md oud_date=oud_md tud_date=tud_md cud_date=cud_md
                               shaud_date=shaud_md stud_date=stud_md hud_date=hud_md iud_date=iud_md))
          a_data01_nacrs (rename=(aud_date=aud_ed oud_date=oud_ed tud_date=tud_ed cud_date=cud_ed
                               shaud_date=shaud_ed stud_date=stud_ed hud_date=hud_ed iud_date=iud_ed))
          a_data01_dad   (rename=(aud_date=aud_dad oud_date=oud_dad tud_date=tud_dad cud_date=cud_dad
                               shaud_date=shaud_dad stud_date=stud_dad hud_date=hud_dad iud_date=iud_dad))
          a_data01_pnet  (rename=(aud_date=aud_rx oud_date=oud_rx tud_date=tud_rx));
    by phn;
    
    /* Keep only participants present in the baseline cohort */
    if in_bl;

    /* 1. Calculate absolute earliest index date across administrative sources */
    aud_date   = min(aud_md, aud_ed, aud_dad, aud_rx);
    oud_date   = min(oud_md, oud_ed, oud_dad, oud_rx);
    tud_date   = min(tud_md, tud_ed, tud_dad, tud_rx);
    cud_date   = min(cud_md, cud_ed, cud_dad, cud_rx);
    shaud_date = min(shaud_md, shaud_ed, shaud_dad, shaud_rx);
    stud_date  = min(stud_md, stud_ed, stud_dad, stud_rx);
    hud_date   = min(hud_md, hud_ed, hud_dad, hud_rx);
    iud_date   = min(iud_md, iud_ed, iud_dad, iud_rx);
    
    format aud_date oud_date tud_date cud_date shaud_date stud_date hud_date iud_date date9.;

    /* 2. Define 1-year look-back window relative to baseline index_date */
    /* Assumes 'index_date' is the baseline interview/enrollment date in r2r_bl */
    array dates[8] aud_date oud_date tud_date cud_date shaud_date stud_date hud_date iud_date;
    array flags[8] aud_flag oud_flag tud_flag cud_flag shaud_flag stud_flag hud_flag iud_flag;

    do i = 1 to 8;
        if not missing(dates[i]) and (indexdate - 365 <= dates[i] <= indexdate) then do;
            flags[i] = 1;
        end;
        else do;
            flags[i] = 0;
            dates[i] = .; /* Set date to missing if outside the 1-year look-back window */
        end;
    end;

    /* 3. Evaluate polysubstance use (2 or more positive disorder flags) */
    if sum(of aud_flag, oud_flag, tud_flag, cud_flag, 
           shaud_flag, stud_flag, hud_flag, iud_flag) >= 2 then polysubstance = 1;
    else polysubstance = 0;

    /* Drop temporary source-specific date variables and loop index */
    drop aud_md oud_md tud_md cud_md shaud_md stud_md hud_md iud_md
     aud_ed oud_ed tud_ed cud_ed shaud_ed stud_ed hud_ed iud_ed
     aud_dad oud_dad tud_dad cud_dad shaud_dad stud_dad hud_dad iud_dad
     aud_rx oud_rx tud_rx cud_rx shaud_rx stud_rx hud_rx iud_rx
     i;
run;









