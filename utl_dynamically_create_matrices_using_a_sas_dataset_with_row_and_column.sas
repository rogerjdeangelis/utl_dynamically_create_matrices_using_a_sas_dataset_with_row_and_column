Dynamically create matrices using a SAS dataset with row and column

 Two solution
    1. SAS
    2. WPS/PROC R or IML/R

see
https://goo.gl/ApQFqR
https://communities.sas.com/t5/SAS-IML-Software-and-Matrix/Dynamically-create-matrices-using-a-SAS-dataset-with-row-and/m-p/421587



INPUT
=====

 WORK.HAVE total obs=2

  YEAR    COUNTRY    METHOD    SEGMENT     ST12    ST13    ST11    ST21    ST23    ST22    ST31    ST32    ST33

  2017      USA       ABC      Retailat     0.2     0.6     0.2     0.3     0.6     0.1     0.1     0.3     0.6
  2017      USA       XYZ      Corporat     0.1     0.5     0.4     0.2     0.6     0.2     0.2     0.3     0.5


WORKING CODE
===========

 SAS
   COMPILE TIME (get the column dimension)

    select max(input(substr(name,4), 2.)) into :dim trimmed
    from sashelp.vcolumn where name eqt "ST"

   MAINLINE (Execution phase)

    * use the number sufix to get row and column indices;
    set have;
    array stin[&sqar.]  st:;
    array stot[&dim.,&dim.]  _temporary_;
    do i=1 to &sqar;
       x=input(substr(vname(stin[i]),3,1),1.);
       y=input(substr(vname(stin[i]),4,1),1.);
       stot[x,y]=stin[i];
    end;


  WPS/R

    have<-have[, order(names(have))];    * reorder based on names;
    ncol<-sqrt(ncol(have));              * get meta data;
    want<-matrix(have, ncol=ncol, byrow=TRUE); * reshape by 3 columns at a time;


OUTPUT
======

 * I cleaned it up for printing;

      [1]    [2]    [3]

 [1]  0.2    0.2    0.6
 [2]  0.3    0.1    0.6
 [3]  0.1    0.3    0.6


      [1]    [2]    [3]

 [1]  0.4    0.1    0.5
 [2]  0.2    0.2    0.6
 [3]  0.2    0.3    0.5


 R
     [,1] [,2] [,3]

 [1,] 0.2  0.2  0.6
 [2,] 0.3  0.1  0.6
 [3,] 0.1  0.3  0.6


*                _              _       _
 _ __ ___   __ _| | _____    __| | __ _| |_ __ _
| '_ ` _ \ / _` | |/ / _ \  / _` |/ _` | __/ _` |
| | | | | | (_| |   <  __/ | (_| | (_| | || (_| |
|_| |_| |_|\__,_|_|\_\___|  \__,_|\__,_|\__\__,_|

;

options validvarname=upcase;
libname sd1 "d:/sd1";
data sd1.have;
input Year$ country$ method$ Segment$ st12 st13 st11 st21 st23 st22 st31 st32 st33;
cards4;
2017 USA ABC Retailat 0.2 0.6 0.2 0.3 0.6 0.1 0.1 0.3 0.6
2017 USA XYZ Corporat 0.1 0.5 0.4 0.2 0.6 0.2 0.2 0.3 0.5
;;;;
run;quit;

*
 ___  __ _ ___
/ __|/ _` / __|
\__ \ (_| \__ \
|___/\__,_|___/

;

 There are only one element of meta data that is needed.
 We need the max row or column dimesion of the square array.

%symdel dim sqar / nowarn;
data _null_;

  * get meta data - proc transpose tends to be much faster on an EG server;
  if _n_=0 then do;
    %let rc=%sysfunc(dosubl('
       proc sql;
          select max(input(substr(name,4), 2.)) into :dim trimmed
          from sashelp.vcolumn where name eqt "ST"
          and libname="SD1"
          and memname="HAVE"
       ;quit;
       %let sqar=%eval(&dim.*&dim.);
    '));
  end;

  set sd1.have;
  array stin[&sqar.]  st:;
  array stot[&dim.,&dim.]  _temporary_;
  do i=1 to &sqar;
     x=input(substr(vname(stin[i]),3,1),1.);
     y=input(substr(vname(stin[i]),4,1),1.);
     stot[x,y]=stin[i];
  end;

  * print the arrays;
  do i=1 to &dim;
    do j=1 to 3;
      put stot[i,j]= @;
    end;
    put;
  end;
run;quit;

*                      ______
__      ___ __  ___   / /  _ \
\ \ /\ / / '_ \/ __| / /| |_) |
 \ V  V /| |_) \__ \/ / |  _ <
  \_/\_/ | .__/|___/_/  |_| \_\
         |_|
;

%macro byrow(dummy);

 %do ro=1 %to 2;

    %utl_submit_wps64('
    libname sd1 sas7bdat "d:/sd1";
    options set=R_HOME "C:/Program Files/R/R-3.3.2";
    libname wrk sas7bdat "%sysfunc(pathname(work))";
    proc r;
    submit;
    source("C:/Program Files/R/R-3.3.2/etc/Rprofile.site", echo=T);
    library(haven);
    library(data.table);
    have<-read_sas("d:/sd1/have.sas7bdat")[&ro,-4:-1];
    have<-have[, order(names(have))];
    ncol<-sqrt(ncol(have));
    want<-matrix(have, ncol=ncol, byrow=TRUE);
    want;
    endsubmit;
    run;quit;
    ');

 %end;

%mend byrow;

%byrow;
