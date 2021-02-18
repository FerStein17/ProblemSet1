clear all
set more off
******************************
*** SET  PREFERENCES ***
******************************
	
	*** Fernando's Laptop
	if "`c(username)'" == "ferna"  {
		global mipath "C:/Users/ferna/OneDrive/Escritorio/ProblemSet1"
	}

	*** Path tree
	global basein 	"$mipath/RawData"
	global baseout   "$mipath/CreatedData"