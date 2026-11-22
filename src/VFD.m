classdef VFD < handle
    % VFD First-order Variable Frequency Drive actuator translating frequency (Hz) to voltage.

    properties
        tau % First-order lag time constant (s)
    end

    methods
        function obj = VFD(Tiempo)
            if nargin > 0
                obj.tau = Tiempo;
            end
        end

        function VariadorDeFrecuencia(obj, MotorRodillo, frecuencia, dt)
            k = ((4 * pi) / MotorRodillo.P) * (((MotorRodillo.Ra * MotorRodillo.Bm) / MotorRodillo.K1) + MotorRodillo.Kb);
            ea_p = (1 / obj.tau) * (frecuencia * k - MotorRodillo.ea);
            MotorRodillo.actualizarEntrada(IntegracionEuler(MotorRodillo.ea, ea_p, dt));
        end
    end
end
