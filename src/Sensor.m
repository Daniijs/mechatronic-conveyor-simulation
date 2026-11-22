classdef Sensor < handle
    % SENSOR First-order low-pass velocity sensor with additive bias and Gaussian noise.

    properties
        % Parameters
        tau               % First-order time constant (63.2% step response)
        Ruido             % Standard deviation of measurement noise (m/s)
        Sesgo             % Constant measurement bias (m/s)

        % States
        VelocidadFiltrada % Internal noise-free filtered state
        VelocidadMedida   % Output measurement (filtered + bias + noise)
    end

    methods
        function obj = Sensor(Tiempo, ruido, sesgo)
            if nargin > 0
                obj.tau = Tiempo;
                obj.Ruido = ruido;
                obj.Sesgo = sesgo;
                obj.VelocidadFiltrada = 0;
                obj.VelocidadMedida = 0;
            end
        end

        function Medir(obj, Cinta, dt)
            % Integrate the clean first-order lag separately so bias/noise do not accumulate.
            V_p = (Cinta.VelocidadCinta - obj.VelocidadFiltrada) / obj.tau;
            obj.VelocidadFiltrada = IntegracionEuler(obj.VelocidadFiltrada, V_p, dt);
            obj.VelocidadMedida = obj.VelocidadFiltrada + obj.Sesgo + obj.Ruido * randn();
        end
    end
end
