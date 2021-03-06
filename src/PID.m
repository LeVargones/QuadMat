% PID: Aplicação de PID
%
% @param      Gains     Os ganhos [kp ki kd]
% @param      x         Vetor de esp est
% @param      SetPoint  Ponto que queremos chegar
% @param      Ref       Qual malha está sendo controlada
% @param      t         Passo de tempo atual
%
% @return     U			Esforço de controle
%
function [U] = PID(Gains, x, SetPoint, Ref, t)
	% Globais do PID
	global err_ant err_int windup t_ant err_dot U_ant err_2ant;
	% Pegando as variáveis de acordo com quem chamou a função
	if strcmp(Ref,'U1')
		idx = 1;
		trgt = x(7);
	elseif strcmp(Ref,'U2')
		idx = 2;
		trgt = x(1);
	elseif strcmp(Ref,'U3')
		idx = 3;
		trgt = x(3);
	elseif strcmp(Ref,'U4')
		idx = 4;
		trgt = x(5);
	end
	% Ganhos do PID
	Kp = Gains(1);
	Ki = Gains(2);
	Kd = Gains(3);
	% Passo de tempo atual
	dt = t - t_ant(idx);
	% Calcula-se o erro
	err = SetPoint - trgt;
	% Tem que verificar se o tempo foi pra frente (os algoritmos ode tem esse comportamento de não seguirem o tempo de forma linear)
	if (t > t_ant(idx))
		% Erro integrativo acumulado
	    err_int(idx) = err_int(idx) + ((err+err_ant(idx))/2)*dt;
	    % Erro derivativo com uma suavização
	    if dt ~= 0
		    if err_dot(idx) == 0
				err_dot(idx) = (err - err_ant(idx))/dt;
		    else
		    	% Isso é feito para reduzir variações bruscas no valor devido a derivada
		    	err_dot(idx) = (err_dot(idx) + (err - err_ant(idx))/dt)/2;
		    end
		else
			err_dot(idx) = 0;
		end
	    % Quase um tony hawk fechando S K A T E aqui
	    P = Kp*err;
	    I = Ki*err_int(idx);
	    D = Kd*err_dot(idx);
	    % Calculando o U com o valor do PID
	    U = Err2U((P+I+D), x, Ref);
	    % Saturação
	    if U > windup(idx)
	    	U = windup(idx);
	    elseif U < -windup(idx)
	    	U = - windup(idx);
	    end
	    % Filtro para a saída (melhorar o esforço de controle)
	    U = U_ant(idx) + (dt/0.01)*(U - U_ant(idx));
	else
		% Caso seja um passo retroativo não faz nada
		U = U_ant(idx);
	end
	% Atualiza as variáveis para o prox passo
 	t_ant(idx) = t;
 	U_ant(idx) = U;
	err_2ant(idx) = err_ant(idx);
	err_ant(idx) = err;
end


%% Err2U: Pega o erro devolve o esforço de controle.
function [U] = Err2U(val, x, Ref)
	% Só isola o valor de cada U das equações de espaço de estados
	% TODO: Fazer o omegar vir nessa equação
    global g L Kf Km m a b;
	if strcmp(Ref,'U1')
		U = (val+g)*m/(cos(x(1))*cos(x(3)));
	elseif strcmp(Ref,'U2')
		U = (val-a(1)*x(6)*x(4))/b(1);
	elseif strcmp(Ref,'U3')
		U = (val-a(3)*x(2)*x(6))/b(2);
	elseif strcmp(Ref,'U4')
		U = (val-a(5)*x(2)*x(4))/b(3);
	end
end