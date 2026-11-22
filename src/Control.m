classdef Control < handle
    % CONTROL Discrete PID controller with output saturation and conditional anti-windup.

    properties
        % Parameters
        Referencia
        P
        I
        D

        % States
        Integral
        Derivada
        Error
        Error_anterior

        % Output saturation limits (Hz)
        Max
        Min
    end

    methods
        function obj = Control(Referencia, P, I, D, Max, Min)
            if nargin > 0
                obj.Referencia = Referencia;
                obj.P = P;
                obj.I = I;
                obj.D = D;
                obj.Max = Max;
                obj.Min = Min;
                obj.Integral = 0;
                obj.Derivada = 0;
                obj.Error = 0;
                obj.Error_anterior = 0;
            end
        end

        function error(obj, Velocidad)
            obj.Error_anterior = obj.Error;
            obj.Error = obj.Referencia - Velocidad;
        end

        function integral(obj, dt)
            obj.Integral = obj.Integral + obj.Error * dt;
        end

        function derivada(obj, dt)
            obj.Derivada = (obj.Error - obj.Error_anterior) / dt;
        end

        function Frecuencia = PID(obj, dt)
            Frecuencia = obj.P * obj.Error + obj.I * obj.Integral + obj.D * obj.Derivada;

            if Frecuencia > obj.Max
                Frecuencia = obj.Max;
                if obj.Error > 0
                    obj.Integral = obj.Integral - obj.Error * dt;
                end
            elseif Frecuencia < obj.Min
                Frecuencia = obj.Min;
                if obj.Error < 0
                    obj.Integral = obj.Integral - obj.Error * dt;
                end
            end
        end
    end
end
