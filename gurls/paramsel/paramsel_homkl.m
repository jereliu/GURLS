function [vout] = paramsel_homkl(X,y,opt)
% paramsel_hopdual(X,y, OPT)
% Performs parameter selection on elastic net parameters for MKL
% The hold-out approach is used.
% The performance measure specified by opt.hoperf is maximized.
%
% INPUTS:
% -OPT: struct of options with the following fields:
%   fields that need to be set through previous gurls tasks:
%		- split (set by the split_* routine)
%		- kernel.K (set by the kernel_* routines)
%   fields (mkl-related) that need to be set by hand:
%       - mkl.L1range (number of L1 penality terms to try)
%       - mkl.L2range (number of L2 penality terms to try)
%
%   fields with default values set through the defopt function:
%		- nlambda
%		- smallnumber
%		- hoperf
%       - nholdouts
%		- kernel.type
%
% OUTPUTS: structure with the following fields:
% -lambdas_round: cell array (opt.nholdoutsX1). For each split a cell 
%       contains the values of the regularization parameter lambda 
%       minimizing the validation error for each class.
% -tau_round: same as above but for tau (L1 penalty term)
% -forho: cell array (opt.nholdoutsX1). For each split a cell contains a 
%         matrix with the validation error for each lambda/tau guess and for 
%         each class
% -guesses: cell array (opt.nholdoutsX1). For each split a cell contains an
%           array of guesses for the regularization parameter lambda
% -lambdas: mean of the optimal lambdas across splits

if isprop(opt,'paramsel')
    vout = opt.paramsel; % lets not overwrite existing parameters.
    % unless they have the same name
else
    opt.newprop('paramsel', struct());
end
vout.guesses = {};

% calculate fit for each hold-out sample
for nh = 1:opt.nholdouts
    % specify holdout sample indices
    if iscell(opt.split)
        tr = opt.split{nh}.tr;
        va = opt.split{nh}.va;
    else
        tr = opt.split.tr;
        va = opt.split.va;
    end
    
    n = size(y(tr), 1);
    
    % specify penalty parameters for mkl
    [Q,L] = eig(opt.kernel.K(tr,tr));
    Q = double(Q);
    L = double(diag(L));
    
    if ~isfield(vout, 'regrange')
        tot = opt.nlambda;
        guesses = paramsel_lambdaguesses(L, r, n, opt);
    else
        tot = numel(vout.regrange);
        guesses = vout.regrange;
    end
    
    ap = zeros(tot,T);
    QtY = Q'*y(tr,:);
    
    if ~isprop(opt, 'rls')
        opt.newprop('rls', struct());
    end
    
    for i = 1:tot
        %%%%%% REPLICATING CODE FROM RLS_DUAL %%%%%%%%
        opt.rls.C = rls_eigen(Q,L,QtY,guesses(i),n);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        if size(X,1) > 0
            Xva = X(va,:);
            opt.rls.X = X(tr,:);
        else
            Xva = [];
        end
        
        yva = y(va,:);
        if strcmp(opt.kernel.type,'linear')
            opt.rls.W = X(tr,:)'*opt.rls.C;
        else
            opt.newprop('predkernel.K', opt.kernel.K(va,tr));
        end
        
        opt.newprop('pred', pred_dual(Xva,yva,opt));
        opt.newprop('perf', opt.hoperf(Xva,yva,opt));
        %p{i} = perf(scores,yho,{'precrec'});
        for t = 1:T
            ap(i,t) = opt.perf.forho(t);
        end
    end
    [~, idx] = max(ap,[],1);
    vout.lambdas_round{nh} = guesses(idx);
    vout.perf{nh} = ap;
    vout.guesses{nh} = guesses;
end

if numel(vout.lambdas_round) > 1
    lambdas = cell2mat(vout.lambdas_round');
    vout.lambdas = median(lambdas);
else
    vout.lambdas = vout.lambdas_round{1};
end
