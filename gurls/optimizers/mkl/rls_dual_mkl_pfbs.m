function [A, epath_trn, epath_tst] = ...
    rls_dual_mkl_pfbs(...
    K_train, y_train, K_test, y_test, ...
    L1_cutoff, L2_ratio, ...
    A_init, iter_max, crit)

% rls_dual_mkl(X, y, opt)
% Proximal Forward Backward Splitting algorithm for elastic net MKL
%
% INPUTS:
% -K: a (n x n x M) array contain M precomputed n x n kernels
% -y: response vector, n x 1 .
% -t: tunning parameter for lasso penalty
% -u: tunning parameter for ridge penalty
%
% OUTPUT: struct with the following fields:
% -W: empty matrix
% -C: matrix of coefficient vectors of dual rls estimator for each class
% -X: training samples used by the routine

M = size(K_train, 3);
n = size(K_train, 1);
n2 = size(K_test, 1);

% 1.prepare data ===
K = K_train;
K_t = K_test;
y = y_train;
y_t = y_test;

adapt = false;

% 2. estimate stepsize sigma = a/2 + u ===
u = (L2_ratio/(1 - L2_ratio)) * eig_app/2;

sigmas = eig_app/10 + u;

% 3. PFBS iteration ===
if isempty(A_init) % n x M container for parameter
    A = zeros(n, M); 
else
    if any(size(A_init) ~= [n, M])
        warning(...
            'wrong A_init dimension [expect %dx%d instead of %dx%d]\n',...
            n, M, size(A_init, 1), size(A_init, 2));
        A = zeros(n, M);
    else
        A = A_init;
    end
end

if isempty(crit) % stopping criteria
    crit = 1e-5;
end
yhat = zeros(n, 1); % prediction


e_list_trn = zeros(1, iter_max + 1);
e_list_tst = zeros(1, iter_max + 1);
e_list_trn(1) = sum(y.^2);

fprintf('\n');
cpb = ConsoleProgressBar(); %set up progress bar
cpb.setMinimum(1); cpb.setMaximum(iter_max);
cpb.start();

for iter = 2:(iter_max + 1)
    % 3.0 store previous step ---
    if adapt
        A_prev = A;
        yhat_prev = yhat;
    end
    
    % 3.1 update a_m (n x 1) ---
    for m = 1:M
        % 3.2.1 GD step
        a_0 = (1 - L2_ratio) * A(:, m) - (yhat - y)/(sigmas*n);
        % 3.2.2 soft thresholding
        f_norm = sqrt(a_0' * K(:,:,m) * a_0);
        A(:, m) = a_0 * max(f_norm - L1_cutoff, 0)/f_norm;
    end
    
    % 3.2. calculate train/pred error ---
    % train
    yhat = zeros(n, 1);
    for m = 1:M
        yhat = yhat + K(:, :, m) * A(:, m);
    end
    e_list_trn(iter) = sum((yhat - y).^2)/sum(y.^2);
    
    % pred
    yhat_pred = zeros(n2, 1);
    for m = 1:M
        yhat_pred_m = K_t(:, :, m) * A(:, m);
        yhat_pred = yhat_pred + yhat_pred_m;
    end
    e_list_tst(iter) = ...
        sum((yhat_pred - y_t).^2)/sum(y_t.^2);
    
    %e_list_tst(iter) = sum((yhat - y).^2)/n;
    
    % 3.3 stepsize, progress bar update, stop condition ---
    if adapt
        da = A - A_prev;
        dg = yhat - yhat_prev;
        sigmas = (n/M) * sum(da' * dg)/(dg' * dg);
    end
    
    cpb.setValue(iter-1);
    
    % stopping condition
    if (abs(e_list_trn(iter) - e_list_trn(iter-1)) < crit)
        break
    end
    
end
cpb.stop(); fprintf('\n');

% clean up response
epath_trn = e_list_trn(2:iter);
epath_tst = e_list_tst(2:iter);

%diag(A'*A)
%plot(1:iter_max, e_list)

end