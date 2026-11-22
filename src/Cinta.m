classdef Cinta < handle
    % CINTA Models the conveyor belt mass, linear velocity, and Coulomb friction.

    properties
        % Parameters
        GrosorCinta
        Muestatico
        Mudinamico
        MasaCinta

        % States
        MasaTotal        % Total mass on the belt (belt + boxes)
        VelocidadCinta
        FuerzaRozamiento
    end

    methods
        function obj = Cinta(GrosorCinta, Muestatico, Mudinamico, MasaCinta)
            if nargin > 0
                obj.GrosorCinta = GrosorCinta;
                obj.Muestatico = Muestatico;
                obj.Mudinamico = Mudinamico;
                obj.MasaCinta = MasaCinta;
                obj.MasaTotal = MasaCinta;
                obj.VelocidadCinta = 0;
                obj.FuerzaRozamiento = 0;
            end
        end

        function ColocarCaja(obj, MasaCaja)
            obj.MasaTotal = obj.MasaTotal + MasaCaja;
        end

        function QuitarCaja(obj, MasaCaja)
            obj.MasaTotal = max(obj.MasaCinta, obj.MasaTotal - MasaCaja);
        end

        function Rozamiento(obj, Rodillo)
            v = obj.VelocidadCinta;
            % Torque at the roller shaft is scaled by the gearbox ratio i.
            F_aplicada = (Rodillo.Motor.TorqueMotor * Rodillo.RelacionTransmision) / Rodillo.RadioEfectivo;
            F_estatica_max = obj.MasaTotal * 9.81 * obj.Muestatico;
            F_dinamica = obj.MasaTotal * 9.81 * obj.Mudinamico;

            if abs(v) < 0.001
                if abs(F_aplicada) < F_estatica_max
                    % Static friction balances the applied tangential force.
                    obj.FuerzaRozamiento = F_aplicada;
                else
                    % Breakaway: oppose the direction of applied force (avoids sign(0) == 0).
                    dir = sign(F_aplicada);
                    if dir == 0
                        dir = sign(v);
                    end
                    obj.FuerzaRozamiento = F_dinamica * dir;
                end
            else
                obj.FuerzaRozamiento = F_dinamica * sign(v);
            end
        end

        function ActualizarEstado(obj, Rodillo)
            obj.Rozamiento(Rodillo);
            obj.VelocidadCinta = Rodillo.VelocidadRodillo * Rodillo.RadioEfectivo;
        end
    end
end
