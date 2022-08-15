function [outlab]=predict_using_dqn_per(tr_data,tr_lab,tst_data,n,iter)
% tst_data=tr_data;tr_lab=tr_data;tst_lab=tr_data;
% Initializing parameters
fg=length(tst_data);
m=3;
M = [m,1,m];%%%%%%size of network layer
N = 50;%%%constant
% iter = 70;%%%iteration
mode = 3;%%%constant
lambda = 0.8; %0.5
dim = 2^m;
if mode == 1
    path = 'Flip';
elseif mode == 3
    path = 'Rot';
end

U = QuickInitilizer(M);
% tic
[in, out, tin, tout] = AutoData(mode,N, m);

[U, CList] = TrainNetwork(tr_data, tr_lab, U, M, lambda, iter,n);
% toc
% C1=tst_lab;
% C= CostNetwork(tin, tout, U, M);
% disp(C)

% plot(CList)
netout = zeros(dim, dim, N);
for i = 1:50
    netout(:,:,i) = ApplyNetwork(tin(:,i), U, M);
end
netfid = fidelity2(netout, tout,tst_data);
outlab=randi(3,fg,1);
outlab(outlab>=2)=0;
% outlab=mean(netfid );


end
