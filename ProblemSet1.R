###### Microeconometr?a avanzada
###### Problem Set 1
###### Analysis

     # 0.0 Descargamos los paquetes

if("dplyr" %in% rownames(installed.packages()) == FALSE) {install.packages("dplyr",repos="http://cran.r-project.org")}
try(suppressPackageStartupMessages(library(dplyr,quietly = TRUE,warn.conflicts = FALSE)),silent = TRUE)
if("tidyr" %in% rownames(installed.packages()) == FALSE) {install.packages("tidyr",repos="http://cran.r-project.org")}
try(suppressPackageStartupMessages(library(tidyr,quietly = TRUE,warn.conflicts = FALSE)),silent = TRUE)
if("tidyverse" %in% rownames(installed.packages()) == FALSE) {install.packages("tidyverse",repos="http://cran.r-project.org")}
try(suppressPackageStartupMessages(library(tidyverse,quietly = TRUE,warn.conflicts = FALSE)),silent = TRUE)
if("stargazer" %in% rownames(installed.packages()) == FALSE) {install.packages("stargazer",repos="http://cran.r-project.org")}
try(suppressPackageStartupMessages(library(stargazer,quietly = TRUE,warn.conflicts = FALSE)),silent = TRUE)
if("hrbrthemes" %in% rownames(installed.packages()) == FALSE) {install.packages("hrbrthemes",repos="http://cran.r-project.org")}
try(suppressPackageStartupMessages(library(hrbrthemes,quietly = TRUE,warn.conflicts = FALSE)),silent = TRUE)
library(haven)                  # Importar bases Stata
library(stats)  


     # 0.1 Definimos el directorio de trabajo

setwd("C:/Users/lalo-/OneDrive/Documentos/Semestre 10/Microeconometria Avanzada/Tarea 1/Bases de Datos/BaseLimpia")
## setwd("C:/Users/ferna/OneDrive/Escritorio/ProblemSet1")


     # 0.2 Importamos la base

datos <- as.data.frame(read_dta("Clean_Data_1.dta"))

####### Comenzamos el an?lisis #######

# Generamos las matrices Z y X

datos <- datos %>% drop_na()

X <- datos[c(1:9,10, 19)]
Z <- datos[c(1, 10:19)]

     # 1.0 Estimaci?n de los par?metros por dos pasos 

# Modelo Probit para estimar Theta

theta <- glm(data = Z, higher_education ~ dum_male + dum_noroeste_rd1 +
                  dum_noreste_rd1 +
                  dum_sureste_rd1 + dum_occidente_rd1  +
                  siblings + broken_family + 
                  parent_education, 
             family = binomial(link = "probit"))

summary(theta)

# Se quito la dummy de centro porque presentaba problemas de colinealidad
# con las otras variables

# Extraemos los coeficientes estimados y generamos z*theta estimada

Z$thetaZ <- predict(theta, Z)

# Generamos los terminos de correcci?n usando la densidad y la acumulada

Z <- Z %>% mutate(terminos_corr = ifelse(higher_education == 1, 
                                      dnorm(thetaZ)/pnorm(thetaZ),
                                      dnorm(thetaZ)/(1 - pnorm(thetaZ))))

# Corremos las treatment-outcome-specific regressions incluyendo los 
# terminos de correccion de seleccion obtenidos en el paso anterior


# Di = 1,
Z.aux <- Z %>% select(c("id", "higher_education", "terminos_corr"))

datos_regY1 <- X %>% left_join(Z.aux,by = "id") %>% filter(higher_education == 1)

regY1 <- lm(data = datos_regY1, y ~ dum_male + age_rd3 +
                 age_squared + dum_noroeste_rd3 +
                 dum_noreste_rd3 + dum_sureste_rd3 + 
                 dum_occidente_rd3 + terminos_corr)

summary(regY1)

rho_sigma1 <- regY1$coefficients["terminos_corr"]
beta1 <- regY1$coefficients[c(1:8)]

# Di = 0 

datos_regY0 <- X %>% left_join(Z.aux, by = "id") %>% filter(higher_education == 0)

regY0 <- lm(data = datos_regY0, y ~ dum_male + age_rd3 +
                 age_squared + dum_noroeste_rd3 +
                 dum_noreste_rd3 + dum_sureste_rd3 + 
                 dum_occidente_rd3 + terminos_corr)

summary(regY0)

rho_sigma0 <- regY0$coefficients["terminos_corr"]
beta0 <- regY0$coefficients[c(1:8)]

# Ya tenemos todos los p?rametros estimados, ahora solo falta usarlos
# para estimar ATE, TT, TUT

     # 2.0) ATE, TT, TUT 
# ATE:

mediasX <- X %>% summarise(across(c(dum_male, age_rd3, age_squared, 
                                    dum_noroeste_rd3, dum_noreste_rd3,
                                    dum_sureste_rd3, dum_occidente_rd3),
                              list(mean))) %>% unlist()

(ATE <- c(1,mediasX) %*% (beta1 - beta0))

# TT:

phi_tt <- mean(Z$terminos_corr[Z$higher_ed == 1])
(TT <- ATE + (rho_sigma1 - rho_sigma0) * phi_tt)

#TUT

phi_tut <- mean(Z$terminos_corr[Z$higher_ed == 0])
(TUT <- ATE + (rho_sigma1 - rho_sigma0) * phi_tut)
                                   

     # 3.0) LATE

# 3.1) Cambio en Broken family de 1 a 0

Z_broken_orig <- Z$broken_family
Z$broken_family <- 0
Z$thetaZ_0 <- predict(theta, Z)
Z$broken_family <- 1
Z$thetaZ_1 <- predict(theta, Z)
phi_0 <- mean(dnorm(Z$thetaZ_0))
phi_1 <- mean(dnorm(Z$thetaZ_1))
Phi_0 <- mean(pnorm(Z$thetaZ_0))
Phi_1 <- mean(pnorm(Z$thetaZ_1))

(LATE_educ <- ATE + (rho_sigma1 - rho_sigma0) * (phi_1 - phi_0)/(Phi_1 - Phi_0))

Z$broken_family <- Z_broken_orig


# 3.2) Cambio en educaci?n de la madre de 0 a 16

Z_educ_orig <- Z$parent_education
Z$parent_education <- 0
Z$thetaZ_0 <- predict(theta, Z)
Z$parent_education <- 16
Z$thetaZ_1 <- predict(theta, Z)
phi_0 <- mean(dnorm(Z$thetaZ_0))
phi_1 <- mean(dnorm(Z$thetaZ_1))
Phi_0 <- mean(pnorm(Z$thetaZ_0))
Phi_1 <- mean(pnorm(Z$thetaZ_1))

(LATE_educ <- ATE + (rho_sigma1 - rho_sigma0) * (phi_1 - phi_0)/(Phi_1 - Phi_0))

Z$parent_education <- Z_educ_orig

# Cambio en los hermanos de 4 a 0

Z_siblings_orig <- Z$siblings
Z$siblings <- 4
Z$thetaZ_0 <- predict(theta, Z)
Z$siblings <- 0
Z$thetaZ_1 <- predict(theta, Z)
phi_0 <- mean(dnorm(Z$thetaZ_0))
phi_1 <- mean(dnorm(Z$thetaZ_1))
Phi_0 <- mean(pnorm(Z$thetaZ_0))
Phi_1 <- mean(pnorm(Z$thetaZ_1))

(LATE_siblings <- ATE + (rho_sigma1 - rho_sigma0) * (phi_1 - phi_0)/(Phi_1 - Phi_0))

Z$siblings <- Z_siblings_orig


        # MTE = ATE CON Ud = 0

(MTE <- ATE)

# Gráfica MTE: 

eje_x <- seq(0,1,length=100)
MTE_y <- as.vector(ATE + (rho_sigma1 - rho_sigma0)*(qnorm(eje_x)))


plot(eje_x, MTE_y,
     main="MTE(u_D)",
     ylab="MTE",
     xlab = "u_d",
     type="l",
     col="blue")

# csv para MatLab

X0 <- X %>% filter(higher_education == 0)
X0 <- select(X0, -10)

write.csv(X0,file = "X_0.csv",row.names = F)
write_xlsx(X0,".xlsx")

X1 <- X %>% filter(higher_education == 1)
X1 <- select(X1, -10)

write.csv(X1,file = "X_1.csv",row.names = F)

Z1 <- Z %>% filter(higher_education == 1)
Z1 <- Z1 %>% mutate(unos = 1)
Z1 <- select(Z1, -2)

write.csv(Z1,file = "Z_1.csv",row.names = F)

Z0 <- Z %>% filter(higher_education == 0)
Z0 <- Z0 %>% mutate(unos = 1)
Z0 <- select(Z0, -2)

write.csv(Z0,file = "Z_0.csv",row.names = F)

Y0 <- datos %>% filter(higher_education == 0)
Y0 <- select(Y0, 2)

write.csv(Y0,file = "Y_0.csv",row.names = F)

Y1 <- datos %>% filter(higher_education == 1)
Y1 <- select(Y1, 2)

write.csv(Y1, file = "Y_1.csv",row.names = F)
