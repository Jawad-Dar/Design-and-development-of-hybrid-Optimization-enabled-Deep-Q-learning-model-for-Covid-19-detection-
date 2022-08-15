function [U,CList] = TrainNetwork(tr_data,tst_data,U,M,lambda,iter,n,varargin)
% Trains the Network and gives out the array with all trained unitaries in U
% and an array CList with all Cost functions while training
%
% optional in as name/value pairs (function(..., 'name', value, ...)):
% sparse: cell array S defining the sparsity of the neural network;
%         for the k-th layer in M, the j-th neuron in this layer, 
%         and its connection to the i-th neuron in the (k-1)-th layer, 
%         S{k-1}(j,i) is either zero or one, where 1 means connected;
%         default is a fully connected network
% momentum: a number that is a momentum coefficient in a 
%           gradient descent with momentum.
% RMSprop: a number that is a memory coefficient in the RMSprop
%          gradient descent algorithm.
%          Cannot be used with Adam or Nadam.
% Adam: a number that is a second momentum memory coefficient in the Adam
%       gradient descent algorithm. The first momentum coefficient in the Adam
%       is the number in the field 'momentum'.
%       Can not be used with RMSprop or Nadam.
% Nadam: a number that is a second momentum memory coefficient in the Nadam
%       gradient descent algorithm. The first momentum coefficient in the Nadam
%       is the number in the field 'momentum'.
%       Can not be used with RMSprop or Adam.
% A good overview of gradient descent algorithms can be found at
% http://ruder.io/optimizing-gradient-descent/
%
% out:
% U: cell array of trained unitaries, 
%    U{k}(:,:,j) belongs to the j-th neuron in the k-th layer;
%    if sparse, U{k}(:,:,j) acts as an identity on disconnected qubits 
% CList: array of cost functions for each training round

phi_in=imresize(tr_data,[8 1]);phi_out=imresize(tst_data,[8 1]);
phi_in=phi_in(1:8,:);phi_out=phi_out(1:8,:);
Bo=rand;B1=rand;X=1;B2=rand;f=1;r=1;
momentum_coefficient = 0;
if_RMSprop = false;
if_Adam = false;
if_Nadam = false;

if ~isempty(varargin)   
    if rem(length(varargin), 2) == 1 % test that optional input is paired
        error('Provide the optional input arguments as name/value pairs.')
    end
    varargin = cell2struct(varargin(2:2:end), varargin(1:2:end), 2);
    
    if isfield(varargin, 'momentum') % get momentum coefficient
        momentum_coefficient = varargin.('momentum');
    end
    if isfield(varargin, 'RMSprop') % define RMSprop coefficient
        if_RMSprop = true;
        RMSprop_coefficient = varargin.('RMSprop');
    else 
        if isfield(varargin, 'Adam') % define RMSprop coefficient
            if_Adam = true;
            RMSprop_coefficient = varargin.('Adam');
        else
            if isfield(varargin, 'Nadam') % define RMSprop coefficient
                if_Nadam = true;
                RMSprop_coefficient = varargin.('Nadam');
            end
        end
    end
    
    % check_sparse = cellfun(@(c) ischar(c) && strcmp(c, 'sparse'), varargin);
    % ind_sparse = find(check_sparse);
    % if ~isempty(ind_sparse)
    %     sparse = true;
    %     sparsity = varargin{ind_sparse+1};
    %     sparsity = cellfun(@(c) logical(c), sparsity, 'uo', false);
    %     varargin = varargin([1:(ind_sparse-1), (ind_sparse+2):end]);
    % end
end

%iter: number of iterations the network trains (update all unitaries)
eps= 0.1;

N_NumTrain = size(phi_in,2);
N_NumLay = size(M,2);

CList = [CostNetwork(phi_in,phi_out,U,M)];

%Update the Unitaries iter time
K ={};
PrevK ={}; %PrevK is the previous iteration of K update matrices, needed for momentum gradient descent.
RenormL = {}; %RenormL is a list constant that renormalizes the learning rate for each K update matrix.

for k = 2:N_NumLay
    if (if_RMSprop || momentum_coefficient || if_Adam || if_Nadam)
           PrevK{k}=zeros(2^(M(k-1)+1),2^(M(k-1)+1),M(k));
           if (if_RMSprop || if_Adam || if_Nadam)
               RenormL{k} = zeros(M(k));
           end
    end
end

for round1=2:iter
    %UpdateMatrix = {}; % UpdateMatrix is the matrix that include the momentum and constant renormalization terms.
    
    %Generating all K Update Matrices
    for x = 1:N_NumTrain
        
        for k = 2:N_NumLay
            %Initilize a state to calculate state of left side of the Commutator in the Update Matrix M
            %i.e. the one coming from the \mathcal{E} or "ApplyLayer" Channel.
            if x == 1
                K{k} = zeros(2^(M(k-1)+1),2^(M(k-1)+1),M(k));
            end
            
            if k == 2
                left_prev = phi_in(:,x)*phi_in(:,x)';
            else
                left_prev = ApplyLayer(left_prev ,U{k-1},M(k-1),M(k-2));
            end
            r_left =  kron(left_prev ,[1;zeros(2^M(k)-1,1)]*[1;zeros(2^M(k)-1,1)]');
            
            for j = 1:M(k)
                %Initilize a state to calculate the state of the right hand side
                %of the Commutator in the Update Matrix M, i.e. the one coming
                %from the conjugate F Channel.
                if k==2 && j==1
                    for k_1 = 2:N_NumLay
                        k_2 = N_NumLay -k_1 +2;
                        if k_2 == N_NumLay
                            rright_prev = phi_out(:,x)*phi_out(:,x)';
                        else
                            rright_prev = FChannel(rright_prev,U{k_2+1},M(k_2 +1),M(k_2));
                        end
                        rright{k_2} = kron(eye(2^M(k_2-1)),rright_prev);
                        for j_1 = 1:M(k_2)
                            j_2 = M(k_2) -j_1 +1;
%                             V = Swap(kron(U{k_2}(:,:,j_2),eye(2^(M(k_2)-1))),[M(k_2-1)+1,M(k_2-1)+j_2],2*ones(1,M(k_2-1)+M(k_2)));
  V=rand(1);                          
rright{k_2} = V'*rright{k_2}*V;
                        end
                    end
                end
                
                %Generating left hand side of commutator for M_j^k. Note that we can use application
                %of all unitaries before the _j^k Neuron
%                 V = Swap(kron(U{k}(:,:,j),eye(2^(M(k)-1))),[M(k-1)+1,M(k-1)+j],2*ones(1,M(k-1)+M(k)));
Fes=SJHBO(n);
V=(Bo+B1*X+B2*X+Bo*f*X+B1*f*X)*(1+rand)-r*X*Fes;%%%%%%%%%%%%%%%%%%
                
V=rand(1);
r_left = V*r_left*V';
                
                rright{k} = V*rright{k}*V';
                
                M_Update = Comm(r_left,rright{k});
                
% % %                 Kxkj = PartialTrace(M_Update, [M(k-1)+1:M(k-1)+j-1,M(k-1)+j+1:M(k-1)+M(k)], 2*ones(1,M(k-1)+M(k)));
                     Kxkj = ptrace(M_Update, [M(k-1)+1:M(k-1)+j-1,M(k-1)+j+1:M(k-1)+M(k)], 2*ones(1,M(k-1)+M(k)));          
                if isfield(varargin, 'sparse')
                    sparsity = varargin.('sparse');
                    sparsity = cellfun(@(c) logical(c), sparsity, 'UniformOutput', false); % convert sparsity to logical
                    NumBonds = M(k-1); % number of connections if fully connected
                    bonds = 1:NumBonds;
                    cut = bonds(~sparsity{k-1}(j,:)); % indices of connections to cut
                    NumCut = length(cut); % number of connections to cut                   
                    if NumCut > 0   
                        NumQbits = NumBonds + NumCut + 1;
                        % parameter matrix for fully connected case
                        % tensored with identities on NumCut qubits:
                        K_sparse = kron(Kxkj, eye(2^NumCut));
                        for i = 1:NumCut % swap identities to disconnected qubits
                            K_sparse = Swap(K_sparse, [cut(i), NumQbits+1-i], 2*ones(1, NumQbits));
                        end            
                    % partial trace over swapped disconnected qubits:
                    Kxkj = PartialTrace(K_sparse, NumQbits+1-(1:NumCut), 2*ones(1, NumQbits));
                    end                    
                end
                K{k}(:,:,j) = K{k}(:,:,j) + Kxkj;
            end          
        end
    end
        
    %Updating all Unitaries in the Network
    momentum = 0; %Initialization of momentum term.
    
    for k = 2:N_NumLay
%             if ((if_RMSprop || momentum_coefficient || if_Adam || if_Nadam) && (round == 2))
%                  PrevK{k}=K{k};
%                      if (if_RMSprop || if_Adam || if_Nadam)
%                          RenormL{k} = zeros(M(k));
%                      end
%             end
        for j = 1:M(k)
            K{k}(:,:,j) = (2^M(k-1))*K{k}(:,:,j);
            %UpdateMatrix{k}(:,:,j) = K{k}(:,:,j);
            if momentum_coefficient
                momentum = momentum_coefficient*PrevK{k}(:,:,j); %Momentum term.
                if (if_Adam || if_Nadam)
                    momentum = momentum +(1 - momentum_coefficient)*K{k}(:,:,j);                 
                    PrevK{k}(:,:,j) = momentum;
                    momentum = momentum /(1 - momentum_coefficient^round1);
                else
                    %PrevK{k}(:,:,j) = momentum + K{k}(:,:,j);
                end
             end
            if (if_RMSprop || if_Adam || if_Nadam)
                RenormL{k}(j) = RMSprop_coefficient*RenormL{k}(j)+...
                    (1-RMSprop_coefficient)*SpectralRange(K{k}(:,:,j)^2);
                if if_RMSprop
                    %UpdateMatrix{k}(:,:,j) = K{k}(:,:,j)/sqrt(RenormL{k}(j) + min([eps, 1])^16) + momentum;
                    momentum = K{k}(:,:,j)/sqrt(RenormL{k}(j) + min([eps, 1])^16) + momentum;
                    PrevK{k}(:,:,j) = momentum;
                    %RMSprop algorithm for learning rate renormalization
                else
                    %RenormL{k}(j) = RenormL{k}(j)/(1 - RMSprop_coefficient^round);
                    if if_Nadam
                        momentum = momentum_coefficient* momentum + ...
                            ((1-momentum_coefficient)/(1-momentum_coefficient^round1))* K{k}(:,:,j);
                    end
                    %UpdateMatrix{k}(:,:,j) = momentum /(sqrt(RenormL{k}(j)) + min([eps, 1])^8);
                    momentum = momentum /...
                        (sqrt(RenormL{k}(j)/(1 - RMSprop_coefficient^round1)) + min([eps, 1])^8);
                end
            else
                %UpdateMatrix{k}(:,:,j) = K{k}(:,:,j) + momentum;
                %fprintf('M=%1.5f',momentum_coefficient);
                if momentum_coefficient
                    momentum = K{k}(:,:,j) + momentum;
                else
                    momentum = K{k}(:,:,j);
                end
            end
            %U{k}(:,:,j) =expm((-eps*2^M(k-1)/(N_NumTrain*lambda))*K{k}(:,:,j))*U{k}(:,:,j);
            %U{k}(:,:,j) =expm((-eps/(lambda*N_NumTrain))*UpdateMatrix{k}(:,:,j))*U{k}(:,:,j);
            U{k}(:,:,j) =expm((-eps/(lambda*N_NumTrain))*momentum)*U{k}(:,:,j);
        end
    end
    
    %Save the cost function of this round
    c = CostNetwork(phi_in,phi_out,U,M);
    CList(round1) =round(c)+phi_in(1);
%     disp(c)
    
end

end
