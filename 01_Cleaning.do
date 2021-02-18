
***********************
** Limpieza Base Rd1 **
***********************

use "$basein/c_ls_1.dta" , clear
tostring folio, gen(str_folio)
tostring ls, gen(str_ls)
gen id = str_folio + str_ls

*Nos quedamos solamente con los que tienen padres en casa
keep if ls06!=51 | ls07!=51 

*Nos quedamos solamente con los que tienen mas de 18 años 


tostring ls07, gen(str_ls07)
gen mother_id = ""
replace mother_id = str_folio + str_ls07

tostring ls06, gen(str_ls06)
gen father_id = ""
replace father_id = str_folio + str_ls06

foreach var of varlist _all {
gen `var'_main =  `var' 
}

drop id 
rename mother_id id


keep id id_main ls05_1_main ls14_main ls04_main father_id_main

save "$baseout/c_ls_aux.dta", replace

merge m:1 id using "$baseout/c_ls_clean.dta"
drop if _merge!=3

*Tenemos missings en mother_education entonces los vamos a matchear con la educacion del padre

keep id_main ls05_1_main ls04_main ls15_1 folio father_id_main
rename ls15_1 mother_education
rename father_id_main id

merge m:1 id using "$baseout/c_ls_clean.dta"
drop if _merge==2

replace mother_education = ls15_1 if mother_education==.
rename mother_education parent_education

keep id_main ls05_1_main ls04_main folio parent_education
rename id_main id


save "$baseout/c_ls_clean.dta", replace


*Tenemos algunos missings con fathe



*Father/Mother HHH
egen siblings = total(ls05_1==3), by(folio) 
replace siblings = siblings - 1 if ls05_1==3
replace siblings = . if ls05_1!=3

*Grandfather/GrandMother HHH
egen siblings_aux =  total(ls05_1==10), by(folio)
replace siblings_aux = . if ls05_1!=10
replace siblings_aux = siblings_aux - 1 if ls05_1==10
replace siblings = siblings_aux if ls05_1==10

*StepFather/StepMother HHH
egen siblings_aux_2 = total(ls05_1==4), by(folio)
replace siblings_aux = . if ls05_1!=4
replace siblings_aux = siblings_aux_2 - 1 if ls05_1==4
replace siblings = siblings_aux_2 if ls05_1==4

keep id siblings ls04 parent_education

save "$baseout/c_ls_clean.dta", replace

use "$basein/iiib_tp.dta" , clear
tostring folio, gen(str_folio)
tostring ls, gen(str_ls)
gen id = str_folio + str_ls
keep id tp02m tp02p 

save "$baseout/iiib_tp_clean.dta", replace

use "$basein/iiib_portad.dta" , clear
tostring folio, gen(str_folio)
tostring ls, gen(str_ls)
gen id = str_folio + str_ls
keep id edad ent

save "$baseout/iiib_portad_clean.dta", replace

use "$baseout/iiib_tp_clean.dta", clear
merge 1:1 id using "$baseout/iiib_portad_clean.dta"
drop if _merge==2
drop _merge

merge 1:1 id using "$baseout/c_ls_clean.dta"
drop if _merge==2
drop _merge

*****************************
** Restricciones Drop Rd 1 **
*****************************

*Nos quedamos con las observaciones con edad menor o igual a 18, y 
keep if edad<=18
keep if tp02m==1 | tp02p==1

rename edad edad_rd1
rename ent ent_rd1

save "$baseout/Rd1_Clean.dta", replace

***********************
** Limpieza Base Rd3 **
***********************
use "$basein/iiia_tb.dta", clear

/* Notemos que el folio es diferente de lo que teníamos en la primera ronda, 
el ls ahora contiene un 0 antes y el folio tiene las letras AP y CP, para que el
análisis pueda ser consistente debemos de retirarlos */

gen str_ls = string(real(ls)) 

*Con ese comando quito los ceros al principio

/*El siguiente programa de Michael Blasnik 
http://www.stata.com/statalist/archi.../msg00353.html nos quita los caracteres */

/*
program define extrnum
version 7
syntax varlist(max=1) , gen(str)
local maxlen: type `varlist'
local maxlen=substr("`maxlen'",4,.)
tempvar work
qui gen str1 `work'=""
forvalues i=1/`maxlen' {
 qui replace `work'=`work'+substr(`varlist',`i',1) if real(substr(`varlist',`i',1))<.
}
gen `gen'=real(`work')
end
*/



extrnum folio, gen(folio_aux)

tostring folio_aux, gen(str_folio)
gen id = str_folio + str_ls


*Con esto mis ids ya son consistentes 
keep id tb35a_2 tb35b_2


*Check ID is unique
duplicates report id
duplicates drop id, force

save "$baseout/iiia_tb_clean.dta", replace

use "$basein/iiia_portad.dta", clear
*Aqui tenemos que hacer lo mismo con los filtros 
gen str_ls = string(real(ls)) 
extrnum folio, gen(folio_aux)
tostring folio_aux, gen(str_folio)
gen id = str_folio + str_ls

keep id edad ent

duplicates report id
duplicates drop id, force

save "$baseout/iiia_portad_clean.dta", replace

use "$basein/iiia_ed.dta", clear
gen str_ls = string(real(ls)) 
extrnum folio, gen(folio_aux)
tostring folio_aux, gen(str_folio)
gen id = str_folio + str_ls

keep id ed06

duplicates report id
duplicates drop id, force

save "$baseout/iiia_ed_clean.dta", replace

use "$basein/iiib_thi.dta", clear
gen str_ls = string(real(ls)) 
extrnum folio, gen(folio_aux)
tostring folio_aux, gen(str_folio)
gen id = str_folio + str_ls

keep id thi01

duplicates report id
duplicates drop id, force

save "$baseout/iiib_thi_clean.dta", replace


use "$baseout/iiia_tb_clean.dta", clear 
merge 1:1 id using "$baseout/iiia_portad_clean.dta"
*All matched
drop _merge

merge 1:1 id using "$baseout/iiia_ed_clean.dta"
*All matched
drop _merge 

merge 1:1 id using "$baseout/iiib_thi_clean.dta"
*Aqui si tenemos unmatched
drop if _merge!=3
drop _merge

rename edad edad_rd3
rename ent ent_rd3

save "$baseout/Rd3_clean.dta", replace

*************************
** Merging 2 Databases **
*************************
merge 1:1 id using "$baseout/Rd1_clean.dta"

*Nos quedamos unicamente con las que estan en ambas bases
drop if _merge!=3
drop _merge

******************************
** Cleaning Merged Database **
******************************
 
*Nos falta que tengan un sueldo positivo
keep if tb35a_2!=.

gen region_rd1 = ""

replace region_rd1 = "Noroeste" if ent_rd1 == 2 | ent_rd1 == 3 | ent_rd1 == 8 | ent_rd1 == 25 | ent_rd1 == 26 
replace region_rd1 = "Noreste" if ent_rd1 == 5 | ent_rd1 == 10 | ent_rd1 == 19 | ent_rd1 == 24 | ent_rd1 == 28 
replace region_rd1 = "Occidente" if ent_rd1 == 1 | ent_rd1 == 6 | ent_rd1 == 11 | ent_rd1 == 14 | ent_rd1 == 16 | ent_rd1 == 18 | ent_rd1 == 22 | ent_rd1 == 32
replace region_rd1 = "Centro" if ent_rd1 == 9 | ent_rd1 == 15 | ent_rd1 == 12 | ent_rd1 == 13 | ent_rd1 == 17 | ent_rd1 == 21| ent_rd1 == 29
replace region_rd1 = "Sureste" if ent_rd1 == 4 | ent_rd1 == 7 | ent_rd1 == 20 | ent_rd1 == 23 | ent_rd1 == 27 | ent_rd1 == 30 | ent_rd1 == 31

gen region_rd3 = ""

replace region_rd3 = "Noroeste" if ent_rd3 == 2 | ent_rd3 == 3 | ent_rd3 == 8 | ent_rd3 == 25 | ent_rd3 == 26 
replace region_rd3 = "Noreste" if ent_rd3 == 5 | ent_rd3 == 10 | ent_rd3 == 19 | ent_rd3 == 24 | ent_rd3 == 28 
replace region_rd3 = "Occidente" if ent_rd3 == 1 | ent_rd3 == 6 | ent_rd3 == 11 | ent_rd3 == 14 | ent_rd3 == 16 | ent_rd3 == 18 | ent_rd3 == 22 | ent_rd3 == 32
replace region_rd3 = "Centro" if ent_rd3 == 9 | ent_rd3 == 15 | ent_rd3 == 12 | ent_rd3 == 13 | ent_rd3 == 17 | ent_rd3 == 21| ent_rd3 == 29
replace region_rd3 = "Sureste" if ent_rd3 == 4 | ent_rd3 == 7 | ent_rd3 == 20 | ent_rd3 == 23 | ent_rd3 == 27 | ent_rd3 == 30 | ent_rd3 == 31

*Generamos variable y = ln(income)
gen y = log(tb35a_2)

*****
* D *
*****
*Vemos la variable educacion a partir de Normal Basic 08 consideramos higher education
gen higher_ed = 0
replace higher_ed = 1 if ed06 == 8 | ed06 == 9 | ed06 == 10 

*****
* X *
*****

*Dummy for male
gen dum_male = 0 
replace dum_male = 1 if ls04 ==1

*age rd3
rename edad_rd3 age_rd3

*age squared
gen age_squared = age_rd3^2

*dummies geographic regions rd3
gen dum_noroeste_rd3 = 0
replace dum_noroeste_rd3 = 1 if region_rd3 == "Noroeste"

gen dum_noreste_rd3 = 0
replace dum_noreste_rd3 = 1 if region_rd3 == "Noreste"

gen dum_occidente_rd3 = 0
replace dum_occidente_rd3 = 1 if region_rd3 == "Occidente"

gen dum_centro_rd3 = 0
replace dum_centro_rd3 = 1 if region_rd3 == "Centro"

gen dum_sureste_rd3 = 0
replace dum_sureste_rd3 = 1 if region_rd3 == "Sureste"

*****
* Z *
*****
*dummies geographic regions rd1
gen dum_noroeste_rd1 = 0
replace dum_noroeste_rd1 = 1 if region_rd1 == "Noroeste"

gen dum_noreste_rd1 = 0
replace dum_noreste_rd1 = 1 if region_rd1 == "Noreste"

gen dum_occidente_rd1 = 0
replace dum_occidente_rd1 = 1 if region_rd1 == "Occidente"

gen dum_centro_rd1 = 0
replace dum_centro_rd1 = 1 if region_rd1 == "Centro"

gen dum_sureste_rd1 = 0
replace dum_sureste_rd1 = 1 if region_rd1 == "Sureste"

*dummy broken family

gen broken_family = 0
replace broken_family = 1 if tp02m !=1 | tp02p !=1

keep id y higher_ed dum_male age_rd3 age_squared dum_noroeste_rd3 dum_noreste_rd3 dum_centro_rd3 dum_occidente_rd3 dum_sureste_rd3 dum_noroeste_rd1 dum_noreste_rd1 dum_centro_rd1 dum_occidente_rd1 dum_sureste_rd1 broken_family parent_education siblings

save "$baseout/Clean_Data.dta", replace










