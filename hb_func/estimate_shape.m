function	[Model] = estimate_shape(data, parm)
% training shape parameter using training data
%
% data.y   = observed spike data with noise 
% data.t   = sample time [sec]
% data.fs  = sampling rate for observed data [Hz]
%
%	parm.fs      =sampling rate for observed data [Hz]
%	parm.fs_est  =estimation freq [Hz]
%	parm.Twin    =
%	parm.Tpre    = 
%	parm.decay    = decay time [sec]
%	                using estimation spike configulation 
%	
%	parm.max_freq = 10;  % max firing frequency [Hz]
%	parm.max_spike = ;
%	parm.Ntau = ;
%
%	Model.tau 
%	Model.a   
%	Model.b   
%	Model.sx  
%	Model.b0
%	Model.sx_list 
%	Model.LogPlist
%	Model.opt_threshold;

% ---- initial search parameter
% Tau.tau_ini  = [0.005; 0.1];
% Tau.max_ini  = max value of tau
% Tau.min_ini  =  grid step
% Tau.step_ini =  grid step
% 
% ---- main search parameter
% Tau.range =  search range of tau
% Tau.step  =  grid step
% Tau.min   =  minimum value
% 

print_mode = 0;

% ----- multiple_spike_state
spike_state = multiple_spike_state(parm, print_mode);

sx_list = [];
py_hist = [];
py_list = [];

% ----- set of 1D-grid  seach parameter
if isfield(parm,'Ntau')
	Tau  = set_tau_grid_cs(parm.Ntau);
else
	Tau  = set_tau_grid_cs;
end

Ntau = Tau.Ntau;

% initial tau for [??1; ??2]
tau  = Tau.tau_ini;

% ------ initial search for [??1; ??2]
%  optimization search for ??2
tau_id = 2;
tau_list = Tau.min_ini(tau_id):...
			Tau.step_ini(tau_id):Tau.max_ini(tau_id);
Model = estimate_shape_step(...
		data, parm, spike_state, tau, tau_id, tau_list);

fprintf('1st-training done\n')

% tau = Model.tau;
% sx_list = [sx_list; Model.sx];
% py_hist = [py_hist; Model.LogPostY];
% py_list = [py_list; Model.LogPostY(end)];
% 
% %  optimization search for ??1
% tau_id = 1;
% tau_list = Tau.min_ini(tau_id):...
% 			Tau.step_ini(tau_id):Tau.max_ini(tau_id);
% tau_list = tau_list( tau_list < tau(2));
% Model = estimate_shape_step(...
% 		data, parm, spike_state, tau, tau_id, tau_list);
% 
% fprintf('--- pre-training done\n')

tau = Model.tau;
sx_list = [sx_list; Model.sx];
py_hist = [py_hist; Model.LogPostY];
py_list = [py_list; Model.LogPostY(end)];

% ------ optimization search for [??1; ??2]
for itr=1:Tau.Nupdate_ini
	for tau_id = 2
	
		tau_list = -Tau.range_ini(tau_id):...
					Tau.step_ini(tau_id): ...
		            Tau.range_ini(tau_id);
		tau_list = tau_list + tau(tau_id);
		
		switch	tau_id
		case	1
			tau_list = tau_list( tau_list < tau(2) ...
			& tau_list <=Tau.max_ini(1) ...
			& tau_list >=Tau.min_ini(1));
		case	2
			tau_list = tau_list( tau_list > tau(1) ...
			& tau_list <=Tau.max_ini(2) ...
			& tau_list >=Tau.min_ini(2));
		end
		
		Model = estimate_shape_step(...
		data, parm, spike_state, tau, tau_id, tau_list);
		
		fprintf('2nd-search (tau_id=%d, itr=%d)\n',...
			tau_id, itr)

		tau = Model.tau;
		sx_list = [sx_list; Model.sx];
		py_hist = [py_hist; Model.LogPostY];
		py_list = [py_list; Model.LogPostY(end)];
	end
end

if  Ntau == 3
	%  ----- optimization search for ??3 
	%        with [??1; ??2; ??3] 
	tau = [tau; Tau.min_ini(3)];
	
	tau_id = 3;
	tau_list = Tau.min_ini(tau_id):...
				Tau.step_ini(tau_id):Tau.max_ini(tau_id);
	tau_list = tau_list( tau_list > tau(2));
	Model = estimate_shape_step(...
		data, parm, spike_state, tau, tau_id, tau_list);
	
	tau = Model.tau;
	sx_list = [sx_list; Model.sx];
	py_hist = [py_hist; Model.LogPostY];
	py_list = [py_list; Model.LogPostY(end)];
end

fprintf('--- initial seach done\n')

% switch	Ntau
% case	2
% 	tau_order = 2;
% case	3
% 	tau_order = 1:3;
% end
% 
% % ------ optimization search for [??1; ??2; ??3] 
% for itr=1:Tau.Nupdate
% 	for tau_id = tau_order
% 	
% 		tau_list = -Tau.range(tau_id):...
% 					Tau.step(tau_id):Tau.range(tau_id);
% 		tau_list = tau_list + tau(tau_id);
% 		
% 		switch	tau_id
% 		case	1
% 			tau_list = tau_list( tau_list < tau(2) ...
% 			& tau_list <=Tau.max(1) ...
% 			& tau_list >=Tau.min(1));
% 		case	2
% 			switch	Ntau
% 			case	2
% 				tau_list = tau_list( tau_list > tau(1) ...
% 				& tau_list <=Tau.max(2) ...
% 				& tau_list >=Tau.min(2));
% 			case	3
% 				tau_list = tau_list( tau_list < tau(3) ...
% 				& tau_list > tau(1) ...
% 				& tau_list <=Tau.max(2) ...
% 				& tau_list >=Tau.min(2));
% 			end
% 		case	3
% 			tau_list = tau_list( tau_list > tau(2) ...
% 			& tau_list <=Tau.max(3) ...
% 			& tau_list >=Tau.min(3));
% 		end
% 		
% 		Model = estimate_shape_step(...
% 		data, parm, spike_state, tau, tau_id, tau_list);
% 		
% 		fprintf('3rd-search (tau_id=%d, itr=%d)\n',...
% 			tau_id, itr)
% 		
% 		tau = Model.tau;
% 		sx_list = [sx_list; Model.sx];
% 		py_hist = [py_hist; Model.LogPostY];
% 		py_list = [py_list; Model.LogPostY(end)];
% 	end
% end
% 
% fprintf('--- Shape seach done\n')

Model.sx_list  = sx_list ;
Model.LogPhist = py_hist;
Model.LogPlist = py_list;

% threshold
if Model.opt_threshold > 2,
	Model.opt_threshold = 2.0;
elseif Model.opt_threshold > 1.0
	Model.opt_threshold = Model.opt_threshold - 0.1;
end

parm.threshold = Model.opt_threshold;
parm.threshold_max = Model.opt_threshold;
% ----- Extract_spike_window;
Data = extract_spike_window(parm, data.y, print_mode);

Model = set_train_parm(Model);

Model = estimate_multispike_step(Model,Data,spike_state);

