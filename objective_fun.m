function f=objective_fun(x,vehicles,rsu)
global i;
% % 
if i<=3
    for ij=1:length(vehicles)
    vehicles(ij).dis_r2v=rand;
    vehicles(ij).pred_energy=rand;vehicles(ij).price=rand;
    end
end
    for ii=length(rsu)
        aa=vehicles(ii).dis_r2v;aa1=vehicles(ii).pred_energy;aad=vehicles(ii).price;
       if isempty(aa1),aa1=randi(length(rsu));end
        f(ii)=log(x(ii)+aa1*aad)+(1-aa);
    end
  f=sum(f(ii));
end

