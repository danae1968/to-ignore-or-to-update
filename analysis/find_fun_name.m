function [fun_name]= find_fun_name(useMod)

switch useMod
    case 'linear'
        fun_name= @discount_lin;
    case 'parabolic'
        fun_name=@discount_para;
    case 'hyperbolic'
        fun_name=@discount_hyp;
    case 'exponential'
        fun_name=@discount_exp;
    case 'linear_bias'
        fun_name= @discount_lin_bias;
    case 'parabolic_bias'
        fun_name=@discount_para_bias;
    case 'hyperbolic_bias'
        fun_name=@discount_hyp_bias;
    case 'exponential_bias'
        fun_name=@discount_exp_bias;
end

%% observational functions
% observation function (hyperbolic)
    function prob = discount_hyp (~, phi, u, ~)
        kappa = exp(phi(1)); % phi(1) = log(kappa), keeps kappa positive
        % subjective value of the easy option
        SV_hard = u(1) ./ (1 + kappa * u(2));
        % subjective value of the task option
        SV_easy = u(3) ./ (1 + kappa * u(4));
        dv = SV_hard - SV_easy;
        beta = phi(2); % inverse temperature
        % mapping from the value space to [0 1]
        prob = VBA_sigmoid(beta.*dv); % sigmoid  y = 1 / (1 + exp(- x))
    end

% observation function (exponential)
    function prob = discount_exp (~, phi, u, ~)
        kappa = exp(phi(1)); % phi(1) = log(kappa), keeps kappa positive
        SV_hard = u(1) .* exp (- kappa * u(2));
        SV_easy = u(3).* exp (- kappa * u(4));
        dv = SV_hard-SV_easy;
        beta = phi(2); % inverse temperature
        prob = VBA_sigmoid(beta.*dv);
    end

% observation function (linear)
    function prob = discount_lin (~, phi, u, ~)
        kappa = exp(phi(1)); % phi(1) = log(kappa), keeps kappa positive
        SV_hard = u(1)  - kappa * u(2);
        SV_easy = u(3)  - kappa * u(4);
        dv = SV_hard-SV_easy;
        beta = phi(2); % inverse temperature
        prob = VBA_sigmoid(beta.*dv);
    end

% observation function (parabolic)
    function prob = discount_para (~, phi, u, ~)
        kappa = exp(phi(1)); % phi(1) = log(kappa), keeps kappa positive
        SV_hard = u(1)-kappa*(u(2))^2;
        SV_easy = u(3)-kappa*(u(4))^2;
        dv = SV_hard-SV_easy;
        beta = phi(2); % inverse temperature
        prob = VBA_sigmoid(beta.*dv);
    end

% observation function (hyperbolic)
    function prob = discount_hyp_bias (~, phi, u, ~)
        % subjective value of the easy option
        kappa = exp(phi(1)); % phi(1) = log(kappa), keeps kappa positive
        SV_hard = u(1) ./ (1 + kappa * u(2));
        % subjective value of the task option
        SV_easy = u(3) ./ (1 + kappa * u(4));
        dv = SV_hard - SV_easy;
        beta = phi(2); % inverse temperature
        prob = VBA_sigmoid(beta.*dv + phi(3)); % sigmoid  y = 1 / (1 + exp(- x))
        
    end

% observation function (exponential)
    function prob = discount_exp_bias (~, phi, u, ~)
        kappa = exp(phi(1)); % phi(1) = log(kappa), keeps kappa positive
        SV_hard = u(1) .* exp (- kappa * u(2));
        SV_easy = u(3).* exp (- kappa * u(4));
        dv = SV_hard-SV_easy;
        beta = phi(2); % inverse temperature
        prob = VBA_sigmoid(beta.*dv+ phi(3));
    end

% observation function (linear)
    function prob = discount_lin_bias (~, phi, u, ~)
        kappa = exp(phi(1)); % phi(1) = log(kappa), keeps kappa positive      
        SV_hard = u(1)  - kappa * u(2);
        SV_easy = u(3)  - kappa * u(4);
        dv = SV_hard-SV_easy;
        beta = phi(2); % inverse temperature
        prob = VBA_sigmoid(beta.*dv+phi(3));
    end

% observation function (parabolic)
    function prob = discount_para_bias (~, phi, u, ~)
        kappa = exp(phi(1)); % phi(1) = log(kappa), keeps kappa positive
        SV_hard = u(1)-kappa*(u(2))^2;
        SV_easy = u(3)-kappa*(u(4))^2;
        dv = SV_hard-SV_easy;
        beta = phi(2); % inverse temperature
        prob = VBA_sigmoid(beta.*dv + phi(3));
    end
end