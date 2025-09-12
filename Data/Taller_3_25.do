************************************************************
* Taller 3 - Evaluación de Impacto
* Fecha: Febrero 2025
************************************************************

clear all // Limpia la memoria eliminando cualquier dato o variable cargada previamente.
set more off // Desactiva la pausa automática en la salida de resultados para que todo se muestre de forma continua.
set varabbrev off // Desactiva la abreviatura automática de nombres de variables para evitar confusiones.

* Cambia el directorio de trabajo a la carpeta especificada para que todos los archivos se guarden y carguen desde allí.
cd "C:\Users\c.castroo\OneDrive - Universidad de los andes\2024\Evaluación de impacto\2025_10\Complementarias\Taller_3_CC"

* Carga la base de datos que contiene información de la línea de base y línea final.
use "data_endline_1and2", clear

* Muestra información descriptiva sobre las variables disponibles en la base de datos.
describe

************************************************************
********************** Punto 2b ****************************
************************************************************

* Se define un conjunto de variables de control que serán utilizadas en las regresiones.
global controles area_pop_base area_business_total_base area_exp_pc_mean_base area_literate_head_base area_literate_base area_debt_total_base

* Se calcula la media de la variable 'spandana_1' para el grupo de control (treatment == 0).
sum spandana_1 if treatment == 0
local mean = round(r(mean), 0.001) // Guarda la media redondeada a tres decimales en una macro local.

* Se realiza una regresión lineal:
* - Variable dependiente: spandana_1
* - Variable independiente de interés: treatment (indicador de tratamiento)
* - Variables de control: definidas en la global $controles
* - Se utilizan ponderaciones (pweight) con la variable w1.
* - Se ajustan los errores estándar agrupados a nivel de 'areaid' para corregir la correlación intra-grupo.
reg spandana_1 treatment $controles [pweight=w1], cluster(areaid)

* Se exportan los resultados de la regresión a un archivo Word (.doc) usando outreg2:
* - El archivo se llama "2_a.doc".
* - Se reemplaza el archivo si ya existe.
* - Se muestra solo el coeficiente de la variable treatment (omitimos la constante).
* - Se incluye el R² ajustado y se muestran tres decimales.
* - Se añade como texto adicional la media del grupo de control calculada anteriormente.
outreg2 using "2_a.doc", replace keep(treatment) nocons adjr2 dec(3) addtext("Control mean", `mean')

************************************************************
********************** Punto 2c ****************************
************************************************************

* Se repite el análisis anterior, pero ahora con la variable 'total_exp_mo_pc_1' (gasto mensual per cápita):
sum total_exp_mo_pc_1 if treatment == 0
local mean = round(r(mean), 0.001) // Se calcula y guarda la media para el grupo de control.

reg total_exp_mo_pc_1 treatment $controles [pweight=w1], cluster(areaid) // Se corre la regresión con las mismas especificaciones.

outreg2 using "2_c.doc", replace keep(treatment) nocons adjr2 dec(3) addtext("Control mean", `mean') // Se exportan resultados.

************************************************************
********************** Punto 2d ****************************
************************************************************

* Se corre una regresión para ver el efecto del tratamiento en la probabilidad de tener un préstamo con alguna institución microfinanciera (anymfi_1).
reg anymfi_1 treatment $controles [pweight=w1], cluster(areaid)

* Se exportan los resultados con un título personalizado y se muestran cuatro decimales.
outreg2 using "2d.doc", ctitle(Cualquier MFI) keep(treatment) dec(4)

************************************************************
***** Opción 2: Cálculo de la tasa de cumplimiento **********
************************************************************

/* 
La tasa de cumplimiento (compliance rate) se refiere a la proporción de personas asignadas al tratamiento que realmente reciben el tratamiento. 
Para calcularla:
1. Calculamos la proporción de individuos tratados entre los asignados al tratamiento (ET1 = Compliers + Always takers).
2. Calculamos la proporción de individuos tratados entre los no asignados al tratamiento (ET0 = Always takers).
3. La tasa de cumplimiento es la diferencia entre ET1 y ET0 (CR = ET1 - ET0).
*/

* 1) Proporción de tratados entre los asignados al tratamiento (ET1 = C + AT)
reg anymfi_1 [pweight=w1] if treatment == 1
scalar ET1 = _b[_cons] // Guarda el intercepto como la proporción estimada de tratados en el grupo de tratamiento.
scalar list // Muestra el valor calculado.

* 2) Proporción de tratados entre los no asignados al tratamiento (ET0 = AT)
reg anymfi_1 [pweight=w1] if treatment == 0
scalar ET0 = _b[_cons] // El intercepto muestra la proporción de 'always takers'.
scalar list

* 3) Cálculo de los cumplidores: CR = ET1 - ET0
scalar CR = ET1 - ET0
scalar list // Muestra la tasa de cumplimiento.

************************************************************
********************** Punto 3b ****************************
************************************************************

* Estimación del efecto causal bajo diferentes métodos.

*** Efecto LATE (Local Average Treatment Effect):
* Se utiliza una regresión instrumental (IV) para estimar el efecto del tratamiento recibido (anymfi_1) sobre el gasto.
* La variable instrumental es 'treatment', que afecta 'anymfi_1' pero solo influye en el gasto a través del acceso a microcréditos.
ivreg2 total_exp_mo_pc_1 (anymfi_1 = treatment) [pweight=w1], cluster(areaid) first

* Se exportan los resultados a "3b.doc" con un título que describe que se trata del efecto LATE.
outreg2 using "3b.doc", replace ctitle(Gastos-LATE)

*** Efecto ITT (Intention To Treat):
* Se estima el efecto de la asignación al tratamiento sobre el gasto sin considerar la tasa de cumplimiento.
ivreg2 total_exp_mo_pc_1 treatment [pweight=w1], cluster(areaid)

* Se exportan los resultados con un título indicativo y sin decimales.
outreg2 using "3b.doc", ctitle(Gastos-ITT) dec(0)
