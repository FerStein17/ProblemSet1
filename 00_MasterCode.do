clear all
set more off
******************************
*** SET  PREFERENCES ***
******************************

// Path Eduardo
/*global mipath "C:\Users\lalo-\OneDrive\Documentos\Semestre 10\Microeconometria Avanzada\Tarea 1\Bases de Datos"
	***
	*Aqui poner la direccion donde se encuentran tus archivos.
	
	*** Path tree
	global basein 	"$mipath/BaseInicial"
	global baseout   "$mipath/BaseLimpia"
	global basein3rd "$mipath/BaseInicial/hh09"*/	
	
	
	*** Fernando's Laptop
	if "`c(username)'" == "ferna"  {
		global mipath "C:/Users/ferna/OneDrive/Escritorio/ProblemSet1"
	}

	*** Path tree
	global basein 	"$mipath/RawData"
	global baseout   "$mipath/CreatedData"
	
	