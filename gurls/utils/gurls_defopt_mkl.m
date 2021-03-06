function opt = gurls_defopt_mkl(opt)

% 	kernel_rbf(opt)
%	Initiate/reset basic parameters for paramsel/rls under dual MKL
%	INPUTS:
%		-OPT: struct generated by gurls_defopt
%
%	OUTPUT: struct with the following fields:
%       -hoperf:    @perf_rmsestd
%       -nholdouts: 5
%		-mkl:       struct of following default values
%           (for paramsel_homkl)
%           -parrange:  (not created) L1/L2 parameter for paramsel
%           (for paramsel_homkl, useful when parrange not set)
%           -npar:      number of L1/L2 terms to be guessed
%           -smallnumber: lower limit of non-zero L1/L2 term to be guessed
%           -stregtegy: whether to use continuation strategy in parameter
%                       estimation.
%           (for rls_dual_mkl_pfbs)
%           -verbose: whether to print progress bar 
%           -iter_max: maximum num of PFBS iteration
%           -crit: convergence criteria on rmsestd in PFBS

% set holdout paramsel parameters
opt.hoperf = @perf_rmsestd;
opt.nholdouts = 5;

% initiate/reset opt.mkl
opt.newprop('mkl', struct());

% for paramsel_mkl
opt.mkl.npar = {25, 5};
opt.mkl.smallnumber = 1e-4;

% for rls_dual_mkl_pfbs in paramsel/rls
opt.mkl.verbose = struct('paramsel', true, 'rls', true);
opt.mkl.iter_max = struct('paramsel', 1e3, 'rls', 1e3);
opt.mkl.crit = struct('paramsel', 1e-3, 'rls', 1e-5);
opt.mkl.strategy = true;
end
