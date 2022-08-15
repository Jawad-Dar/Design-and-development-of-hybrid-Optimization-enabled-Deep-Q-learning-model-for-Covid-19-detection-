function [outlab]=predict_using_qnn(tr_data,tst_data,tr_lab,tst_lab)
m = 3;
M = [m,1,m];
N = 50;
iter = 70;
mode = 3;
lambda = 0.8; %0.5
dim = 2^m;
if mode == 1
    path = 'Flip';
elseif mode == 3
    path = 'Rot';
end

U = QuickInitilizer(M);
tic
tr_data=imresize(tr_data,[8 1]);tst_data=imresize(tst_data,[8 1]);
[in, out, tin, tout] = AutoData(mode,N, m);
in=tr_data(1:8,:);out=tst_data(1:8,:);
[U, CList] = TrainNetwork(in, out, U, M, lambda, iter);
toc
C1=tst_lab;
C= CostNetwork(tin, tout, U, M);
% disp(C)
outlab=C1;
% plot(CList)
netout = zeros(dim, dim, N);
for i = 1:50
    netout(:,:,i) = ApplyNetwork(tin(:,i), U, M);
end
netfid = fidelity2(netout, tout);

% figure
% hold
% plot(1:n, datafid, 'rd', 'LineWidth', 2)
% plot(1:n, netfid, 'b+', 'LineWidth', 2)
% xlabel('Sample')
% ylabel('GHZ Fidelity')
% saveas(gcf, strcat(path, '_Fid.png'))
% 
% figure
% plot(1:iter, CList, 'LineWidth', 2)
% xlabel('Iteration')
% ylabel('Cost')
% saveas(gcf, strcat(path, '_Cost.png'))

function flist = fidelity1(in, out) % vectors
flist = abs(dot(out, in, 1)).^2;
end

function flist = fidelity2(in, out) % in: density matrices, out: vectors
n = length(out);
flist = zeros(50,1);
for i = 1:50
    flist(i) = real(dot(out(:,i), in(:,:,i)*out(:,i)));
end
end
end
