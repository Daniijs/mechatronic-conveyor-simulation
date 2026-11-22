classdef Rodillo < handle
    % RODILLO Drive roller and gearbox coupling motor mechanics to the conveyor belt.

    properties
        % Linked components
        Motor Motor
        Cinta Cinta

        % Parameters
        RadioRodillo
        RelacionTransmision

        % Derived parameters
        RadioEfectivo

        % States
        VelocidadRodillo
        PosicionAngular
    end

    methods
        function obj = Rodillo(Motor, Cinta, RadioRodillo, RelacionTransmision)
            if nargin > 0
                obj.Motor = Motor;
                obj.Cinta = Cinta;
                obj.RadioRodillo = RadioRodillo;
                if nargin > 3
                    obj.RelacionTransmision = RelacionTransmision;
                else
                    obj.RelacionTransmision = 1;
                end
                obj.RadioEfectivo = obj.RadioRodillo + (obj.Cinta.GrosorCinta / 2);
                obj.VelocidadRodillo = 0;
                obj.PosicionAngular = 0;
            end
        end

        function TorqueDeCarga(obj)
            % Load torque reflected to the motor shaft scales by 1 / i.
            obj.Motor.Tl = (obj.Cinta.FuerzaRozamiento * obj.RadioEfectivo) / obj.RelacionTransmision;
        end

        function InerciaTotal(obj)
            % Belt translational inertia reflected to the motor shaft scales by 1 / i^2.
            obj.Motor.Jt = obj.Motor.Jm + (obj.Cinta.MasaTotal * (obj.RadioEfectivo ^ 2)) / (obj.RelacionTransmision ^ 2);
        end

        function ActualizarPosicion(obj, dt)
            obj.PosicionAngular = mod(obj.PosicionAngular + obj.VelocidadRodillo * dt, 2 * pi);
        end

        function ActualizarEstado(obj, dt)
            obj.VelocidadRodillo = obj.Motor.VelocidadMotor / obj.RelacionTransmision;
            obj.ActualizarPosicion(dt);
            obj.TorqueDeCarga();
            obj.InerciaTotal();
        end
    end
end
