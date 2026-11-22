classdef Motor < handle
    % MOTOR Electromechanical armature + rotor dynamics model.

    properties
        % Input
        ea % Armature voltage (V)

        % Parameters
        Ra % Armature resistance (Ohm)
        La % Armature inductance (H)
        Bm % Viscous damping coefficient (N*m*s/rad)
        Jm % Rotor moment of inertia (kg*m^2)
        K1 % Torque constant (N*m/A)
        Kb % Back-EMF constant (V*s/rad)
        P  % Equivalent pole count for VFD V/f scaling

        % Reflected load parameters
        Tl % Reflected load torque (N*m)
        Jt % Total reflected inertia (kg*m^2)
        eb % Back-EMF voltage (V)

        % States
        IntensidadArmadura
        VelocidadMotor
        PosicionAngular
        TorqueMotor
    end

    methods
        function obj = Motor(Resistencia, Inductancia, CoeficienteViscosidad, InerciaMotor, CoeficienteTorque, ConstanteInduccion, Polos)
            if nargin > 0
                obj.ea = 0;
                obj.Ra = Resistencia;
                obj.La = Inductancia;
                obj.Bm = CoeficienteViscosidad;
                obj.Jm = InerciaMotor;
                obj.K1 = CoeficienteTorque;
                obj.Kb = ConstanteInduccion;
                obj.P = Polos;
                obj.Tl = 0;
                obj.Jt = obj.Jm;
                obj.eb = 0;
                obj.IntensidadArmadura = 0;
                obj.VelocidadMotor = 0;
                obj.PosicionAngular = 0;
                obj.TorqueMotor = 0;
            end
        end

        function actualizarEntrada(obj, Tension)
            obj.ea = Tension;
        end

        function ActualizarIntensidad(obj, dt)
            obj.eb = obj.Kb * obj.VelocidadMotor;
            ia_p = (1 / obj.La) * (obj.ea - obj.Ra * obj.IntensidadArmadura - obj.eb);
            obj.IntensidadArmadura = IntegracionEuler(obj.IntensidadArmadura, ia_p, dt);
        end

        function ActualizarVelocidad(obj, dt)
            w_p = (1 / obj.Jt) * (obj.K1 * obj.IntensidadArmadura - obj.Bm * obj.VelocidadMotor - obj.Tl);
            obj.VelocidadMotor = IntegracionEuler(obj.VelocidadMotor, w_p, dt);

            % Prevent reverse rotation (unidirectional VFD without regenerative braking).
            if obj.VelocidadMotor < 0
                obj.VelocidadMotor = 0;
            end

            obj.PosicionAngular = mod(obj.PosicionAngular + obj.VelocidadMotor * dt, 2 * pi);
        end

        function actualizarEstado(obj, dt)
            obj.ActualizarIntensidad(dt);
            obj.ActualizarVelocidad(dt);
            obj.TorqueMotor = obj.IntensidadArmadura * obj.K1;
        end
    end
end
