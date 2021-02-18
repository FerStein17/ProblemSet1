function [F] = ML(v, xo,zo,yo,x1,z1,y1)


n1 = length(y1);
no = length(yo);



Do = 1;
D1 = 1;

%% Escribimos la maximum liklehood usando la exponencial y la tanh para evitar que la varianza sea negativa y que la correlacion se encuentre entre -1 y 1. 


for i = 1:no - 1
    
    Do = (1 / (exp(v(1))*sqrt(2*pi)) )*(( exp(-0.5*((yo(i)- xo(i,:)*v(5:12)')/exp(v(1)) )))^2)*(normcdf( (zo(i,:)* v(21:29)'   + (yo(i) - xo(i,:)*v(5:12)')* (tanh(v(3))^2)/exp(v(1)))*( 1 / sqrt(1 - tanh(v(3))^2) )  ) ) ;
    

end

for i = 1:(n1 - 1 ) 
    
    
    D1 = (1 / (exp(v(2))*sqrt(2*pi)) )*(( exp(-0.5*((y1(i)- x1(i,:)*v(13:20)')/exp(v(2)) )))^2)*(1 - normcdf( (z1(i,:)* v(21:29)'   + (y1(i) - x1(i,:)*v(13:20)')* (tanh(par(4))^2)/exp(v(2)))*( 1 / sqrt(1 - tanh(v(4))^2) )  ) ) ;
    
end



F = Do*D1;


end
